// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {PirexERC4626} from "src/vaults/PirexERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {PirexGmx} from "src/PirexGmx.sol";
import {PirexRewards} from "src/PirexRewards.sol";
import {IV3SwapRouter} from "src/interfaces/IV3SwapRouter.sol";
import {ICamelotRouter} from "src/interfaces/ICamelotRouter.sol";
import {IPirexGmxDepositRouter} from "src/interfaces/IPirexGmxDepositRouter.sol";

contract AutoPxGmx is ReentrancyGuard, Owned, PirexERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    IV3SwapRouter public constant SWAP_ROUTER =
        IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    ICamelotRouter public constant CAMELOT_ROUTER =
        ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    uint256 public constant MAX_WITHDRAWAL_PENALTY = 500;
    uint256 public constant MAX_PLATFORM_FEE = 2_000;
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant MAX_COMPOUND_INCENTIVE = 5_000;

    // Address of the rewards module (ie. PirexRewards instance)
    address public immutable rewardsModule;

    ERC20 public immutable gmxBaseReward;
    ERC20 public immutable gmx;

    // Calemot swap refferal address
    address public calemotReferral;

    uint256 public withdrawalPenalty = 300;
    uint256 public platformFee = 1_000;
    uint256 public compoundIncentive = 1_000;
    address public platform;
    address public depositRouter;

    // Uniswap pool fee
    uint24 public poolFee = 3_000;

    // Receives and distributes platform fees
    address public immutable pirexFees;

    // Maintain the amount of total assets after each vault operation that affects it
    // In this case, pxGMX was added as a result of the compound operation
    // This allows us to maintain a delayed account of pxGMX, preventing external operators
    // from claiming the rewards independently from the vault
    uint256 public vaultTotalAssets;

    event PoolFeeUpdated(uint24 _poolFee);
    event WithdrawalPenaltyUpdated(uint256 penalty);
    event PlatformFeeUpdated(uint256 fee);
    event CompoundIncentiveUpdated(uint256 incentive);
    event PlatformUpdated(address _platform);
    event SetReferral(address referrer);
    event Compounded(
        address indexed caller,
        uint24 fee,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96,
        uint256 gmxBaseRewardAmountIn,
        uint256 gmxAmountOut,
        uint256 pxGmxMintAmount,
        uint256 totalFee,
        uint256 incentive
    );

    error ZeroAmount();
    error ZeroAddress();
    error InvalidAssetParam();
    error ExceedsMax();
    error AlreadySet();
    error InvalidParam();
    error ZeroShares();

    /**
        @param  _gmxBaseReward  address  GMX reward token contract address
        @param  _gmx            address  GMX token contract address
        @param  _asset          address  Asset address (e.g. pxGMX)
        @param  _name           string   Asset name (e.g. Autocompounding pxGMX)
        @param  _symbol         string   Asset symbol (e.g. apxGMX)
        @param  _platform       address  Platform address (e.g. PirexGmx)
        @param  _rewardsModule  address  Rewards module address
        @param  _pirexFees      address  PirexFees contract address
     */
    constructor(
        address _gmxBaseReward,
        address _gmx,
        address _asset,
        string memory _name,
        string memory _symbol,
        address _platform,
        address _rewardsModule,
        address _pirexFees,
        address _depositRouter
    ) Owned(msg.sender) PirexERC4626(ERC20(_asset), _name, _symbol) {
        if (_gmxBaseReward == address(0)) revert ZeroAddress();
        if (_gmx == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();
        if (bytes(_name).length == 0) revert InvalidAssetParam();
        if (bytes(_symbol).length == 0) revert InvalidAssetParam();
        if (_platform == address(0)) revert ZeroAddress();
        if (_rewardsModule == address(0)) revert ZeroAddress();
        if (_pirexFees == address(0)) revert ZeroAddress();
        if (_depositRouter == address(0)) revert ZeroAddress();

        gmxBaseReward = ERC20(_gmxBaseReward);
        gmx = ERC20(_gmx);
        platform = _platform;
        rewardsModule = _rewardsModule;
        pirexFees = _pirexFees;
        depositRouter = _depositRouter;

        // Approve the Uniswap V3 and Camelot routers to manage our base reward (inbound swap token)
        gmxBaseReward.safeApprove(address(SWAP_ROUTER), type(uint256).max);
        gmxBaseReward.safeApprove(address(CAMELOT_ROUTER), type(uint256).max);
        gmx.safeApprove(_depositRouter, type(uint256).max);
        gmx.safeApprove(_platform, type(uint256).max);
    }

    /**
        @notice Constructs ExactInputSingleParams with constant field values pre-defined (e.g. recipient)
        @param  amountIn           uint256                               Input token amount
        @param  amountOutMinimum   uint256                               Minimum output token amount
        @param  sqrtPriceLimitX96  uint160                               The Q64.96 sqrt price limit
        @return                    IV3SwapRouter.ExactInputSingleParams
     */
    function _getExactInputSingleParams(
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) private view returns (IV3SwapRouter.ExactInputSingleParams memory) {
        return
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(gmxBaseReward),
                tokenOut: address(gmx),
                fee: poolFee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });
    }

    /**
        @notice Set the Uniswap pool fee
        @param  _poolFee  uint24  Uniswap pool fee
     */
    function setPoolFee(uint24 _poolFee) external onlyOwner {
        if (_poolFee == 0) revert ZeroAmount();

        poolFee = _poolFee;

        emit PoolFeeUpdated(_poolFee);
    }

    /**
        @notice Set the withdrawal penalty
        @param  penalty  uint256  Withdrawal penalty
     */
    function setWithdrawalPenalty(uint256 penalty) external onlyOwner {
        if (penalty > MAX_WITHDRAWAL_PENALTY) revert ExceedsMax();

        withdrawalPenalty = penalty;

        emit WithdrawalPenaltyUpdated(penalty);
    }

    /**
        @notice Set the platform fee
        @param  fee  uint256  Platform fee
     */
    function setPlatformFee(uint256 fee) external onlyOwner {
        if (fee > MAX_PLATFORM_FEE) revert ExceedsMax();

        platformFee = fee;

        emit PlatformFeeUpdated(fee);
    }

    /**
        @notice Set the compound incentive
        @param  incentive  uint256  Compound incentive
     */
    function setCompoundIncentive(uint256 incentive) external onlyOwner {
        if (incentive > MAX_COMPOUND_INCENTIVE) revert ExceedsMax();

        compoundIncentive = incentive;

        emit CompoundIncentiveUpdated(incentive);
    }

    /**
        @notice Set the platform
        @param  _platform  address  Platform
     */
    function setPlatform(address _platform) external onlyOwner {
        if (_platform == address(0)) revert ZeroAddress();

        platform = _platform;

        emit PlatformUpdated(_platform);
    }

    function SetDepositRouter(address _router) external onlyOwner {
        if (_router == address(0)) revert ZeroAddress();

        // Update GMX transfer allowance for the old and new platforms
        gmx.safeApprove(depositRouter, 0);
        gmx.safeApprove(_router, type(uint256).max);

        depositRouter = _router;
    }

    /**
        @notice Set the Camelot referral address
        @param  referrer  address  Referral address
     */
    function setCamelotReferral(address referrer) external onlyOwner {
        calemotReferral = referrer;

        emit SetReferral(referrer);
    }

    /**
        @notice Get the pxGMX custodied by the AutoPxGmx contract
        @return uint256  Amount of pxGMX custodied by the autocompounder
     */
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
        @notice Preview the amount of assets a user would receive from redeeming shares
        @param  shares  uint256  Shares
        @return uint256  Assets
     */
    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        // Calculate assets based on a user's % ownership of vault shares
        uint256 assets = convertToAssets(shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a penalty - zero if user is the last to withdraw
        uint256 penalty = (_totalSupply == 0 || _totalSupply - shares == 0)
            ? 0
            : assets.mulDivDown(withdrawalPenalty, FEE_DENOMINATOR);

        // Redeemable amount is the post-penalty amount
        return assets - penalty;
    }

    /**
        @notice Preview the amount of shares a user would need to redeem the specified asset amount
        @notice This modified version takes into consideration the withdrawal fee
        @param  assets   uint256  Assets
        @return          uint256  Shares
     */
    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        // Calculate shares based on the specified assets' proportion of the pool
        uint256 shares = convertToShares(assets);

        // Save 1 SLOAD
        uint256 _totalSupply = totalSupply;

        // Factor in additional shares to fulfill withdrawal if user is not the last to withdraw
        return
            (_totalSupply == 0 || _totalSupply - shares == 0)
                ? shares
                : shares.mulDivUp(
                    FEE_DENOMINATOR,
                    FEE_DENOMINATOR - withdrawalPenalty
                );
    }

    /**
        @notice Return the maximum amount of assets the specified account can withdraw
        @param  account  address  Account address
        @return          uint256  Assets
     */
    function maxWithdraw(address account)
        public
        view
        override
        returns (uint256)
    {
        return previewRedeem(balanceOf[account]);
    }

    /**
        @notice Compound pxGMX rewards before depositing
     */
    function beforeDeposit(
        address,
        uint256,
        uint256
    ) internal override {
        compound(1, 0, true);
    }

    function afterWithdraw(
        address,
        uint256,
        uint256
    ) internal override {
        vaultTotalAssets = totalAssets();
    }

    function afterDeposit(
        address,
        uint256,
        uint256
    ) internal override {
        vaultTotalAssets = totalAssets();
    }

    /**
        @notice Compound pxGMX rewards
        @param  amountOutMinimum       uint256  Outbound token swap amount
        @param  sqrtPriceLimitX96      uint160  Swap price impact limit (optional)
        @param  optOutIncentive        bool     Whether to opt out of the incentive
        @return gmxBaseRewardAmountIn  uint256  GMX base reward inbound swap amount
        @return gmxAmountOut           uint256  GMX outbound swap amount
        @return pxGmxAmountOut         uint256  pxGMX minted or swapped from gmxBaseReward rewards
        @return totalFee               uint256  Total platform fee
        @return incentive              uint256  Compound incentive
     */
    function compound(
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96,
        bool optOutIncentive
    )
        public
        returns (
            uint256 gmxBaseRewardAmountIn,
            uint256 gmxAmountOut,
            uint256 pxGmxAmountOut,
            uint256 totalFee,
            uint256 incentive
        )
    {
        if (amountOutMinimum == 0) revert InvalidParam();

        uint256 assetsBeforeClaim = vaultTotalAssets != 0
            ? vaultTotalAssets
            : totalAssets();

        // Make sure reward acrruals are up-to-date
        PirexRewards(rewardsModule).accrueAndClaim(address(this));

        // Swap entire reward balance for GMX
        gmxBaseRewardAmountIn = gmxBaseReward.balanceOf(address(this));

        if (gmxBaseRewardAmountIn != 0) {
            address[] memory path = new address[](2);
            path[0] = address(gmxBaseReward);
            path[1] = address(asset);

            // Get the expectedAmountOut for ETH/pxGMX swap
            uint256 expectedAmountOut = CAMELOT_ROUTER.getAmountsOut(
                gmxBaseRewardAmountIn,
                path
            )[1];

            // Calculate equivalent GMX amount for swap+deposit
            uint256 minGmxAmount = expectedAmountOut.mulDivUp(
                1_000_000,
                1_000_000 -
                    PirexGmx(platform).fees(PirexGmx.Fees.Deposit)
            );

            // Try to swap for minGmxAmount
            try
                SWAP_ROUTER.exactInputSingle(
                    _getExactInputSingleParams(
                        gmxBaseRewardAmountIn,
                        minGmxAmount,
                        sqrtPriceLimitX96
                    )
                )
            returns (uint256 amountOut) {
                gmxAmountOut = amountOut;
                // Deposit entire GMX balance for pxGMX, increasing the asset/share amount
                // pxGmxAmountOut is the pxGMX received by the vault *after* Pirex-GMX fees
                (pxGmxAmountOut, ) = PirexGmx(platform).depositGmx(
                    gmx.balanceOf(address(this)),
                    address(this)
                );
            } catch {
                uint256 pxGmxBalanceBefore = asset.balanceOf(address(this));
                // If the swap fails, swap directly for pxGMX
                CAMELOT_ROUTER
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        gmxBaseRewardAmountIn,
                        amountOutMinimum,
                        path,
                        address(this),
                        calemotReferral,
                        type(uint256).max
                    );

                pxGmxAmountOut = asset.balanceOf(address(this)) - pxGmxBalanceBefore;
            }
        }

        // Only distribute fees if the amount of vault assets increased
        uint256 newAssets = totalAssets() - assetsBeforeClaim;
        if (newAssets != 0) {
            totalFee = newAssets.mulDivDown(platformFee, FEE_DENOMINATOR);
            incentive = optOutIncentive
                ? 0
                : totalFee.mulDivDown(compoundIncentive, FEE_DENOMINATOR);

            if (incentive != 0) asset.safeTransfer(msg.sender, incentive);

            asset.safeTransfer(pirexFees, totalFee - incentive);
        }

        vaultTotalAssets = totalAssets();

        emit Compounded(
            msg.sender,
            poolFee,
            amountOutMinimum,
            sqrtPriceLimitX96,
            gmxBaseRewardAmountIn,
            gmxAmountOut,
            pxGmxAmountOut,
            totalFee,
            incentive
        );
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address account
    ) public override returns (uint256 shares) {
        // Compound rewards and ensure they are properly accounted for prior to withdrawal calculation
        compound(1, 0, true);

        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != account) {
            uint256 allowed = allowance[account][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[account][msg.sender] = allowed - shares;
        }

        _burn(account, shares);

        emit Withdraw(msg.sender, receiver, account, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(account, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address account
    ) public override returns (uint256 assets) {
        // Compound rewards and ensure they are properly accounted for prior to redemption calculation
        compound(1, 0, true);

        if (msg.sender != account) {
            uint256 allowed = allowance[account][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[account][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _burn(account, shares);

        emit Withdraw(msg.sender, receiver, account, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(account, assets, shares);
    }

    /**
        @notice Deposit GMX for apxGMX
        @param  amount    uint256  GMX amount
        @param  receiver  address  apxGMX receiver
        @return shares    uint256  Vault shares (i.e. apxGMX)
     */
    function depositGmx(uint256 amount, address receiver)
        external
        nonReentrant
        returns (uint256 shares)
    {
        if (amount == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Handle compounding of rewards before deposit (arguments are not used by `beforeDeposit` hook)
        if (totalAssets() != 0) beforeDeposit(address(0), 0, 0);

        // Intake sender GMX
        gmx.safeTransferFrom(msg.sender, address(this), amount);

        // Convert sender GMX into pxGMX and get the post-fee amount (i.e. assets)
        (uint256 postFeeAssets, ) = IPirexGmxDepositRouter(depositRouter).depositGmx(
            amount,
            address(this)
        );

        // NOTE: Modified `convertToShares` logic to consider assets already being in the vault
        // and handle it by deducting the recently-deposited assets from the total
        uint256 supply = totalSupply;

        if (
            (shares = supply == 0
                ? postFeeAssets
                : postFeeAssets.mulDivDown(
                    supply,
                    totalAssets() - postFeeAssets
                )) == 0
        ) revert ZeroShares();

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, postFeeAssets, shares);

        afterDeposit(receiver, postFeeAssets, shares);
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
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
/**
    @notice Pirex modifications
            - Add beforeDeposit method
            - Call beforeDeposit in deposit and mint methods
            - Add afterWithdraw method
            - Call afterWithdraw in redeem and withdraw methods
            - Add beforeTransfer method
            - Call beforeTransfer in transfer and transferFrom methods
 */
abstract contract PirexERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        public
        virtual
        returns (uint256 shares)
    {
        beforeDeposit(receiver, assets, shares);

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        returns (uint256 assets)
    {
        beforeDeposit(receiver, assets, shares);

        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        beforeWithdraw(owner, assets, shares); // Note that shares is still 0 here

        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(owner, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        beforeWithdraw(owner, assets, shares); // Note that assets is still 0 here

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /**
        @notice Override transfer method to allow for pre-transfer internal hook
        @param  to      address  Account receiving apxGLP
        @param  amount  uint256  Amount of apxGLP
    */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        beforeTransfer(msg.sender, to, amount);

        return ERC20.transfer(to, amount);
    }

    /**
        @notice Override transferFrom method to allow for pre-transfer internal hook
        @param  from    address  Account sending apxGLP
        @param  to      address  Account receiving apxGLP
        @param  amount  uint256  Amount of apxGLP
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        beforeTransfer(from, to, amount);

        return ERC20.transferFrom(from, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {}

    function beforeDeposit(
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {}

    function afterWithdraw(
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {}

    function afterDeposit(
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {}

    function beforeTransfer(
        address owner,
        address receiver,
        uint256 amount
    ) internal virtual {}
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
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

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
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Modified ReentrancyGuard which changes `locked`'s visibility to internal
import {ReentrancyGuard} from "src/lib/ReentrancyGuard.sol";

import {Owned} from "solmate/auth/Owned.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {PxERC20} from "src/PxERC20.sol";
import {PirexFees} from "src/PirexFees.sol";
import {RewardTracker} from "src/external/RewardTracker.sol";
import {IDelegateRegistry} from "src/interfaces/IDelegateRegistry.sol";
import {IRewardRouterV2} from "src/interfaces/IRewardRouterV2.sol";
import {IStakedGlp} from "src/interfaces/IStakedGlp.sol";
import {IRewardDistributor} from "src/interfaces/IRewardDistributor.sol";
import {IPirexRewards} from "src/interfaces/IPirexRewards.sol";
import {IGlpManager} from "src/interfaces/IGlpManager.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {PirexGmxCooldownHandler} from "src/PirexGmxCooldownHandler.sol";

/**
    @title  Pirex protocol #2: Pirex-GMX, a composable GMX derivatives protocol
    @author kphed (GitHub)
    @author drahrealm (GitHub)

    Dedicated to Jude 🐾
*/
contract PirexGmx is ReentrancyGuard, Owned, Pausable {
    using SafeTransferLib for ERC20;

    // Configurable fees
    enum Fees {
        Deposit,
        Redemption,
        Reward
    }

    // Configurable external contracts
    enum Contracts {
        RewardRouterV2,
        GlpRewardRouterV2,
        RewardTrackerGmx,
        RewardTrackerGlp,
        FeeStakedGlp,
        StakedGmx,
        StakedGlp,
        GmxVault,
        GlpManager
    }

    // Fee denominator
    uint256 public constant FEE_DENOMINATOR = 1_000_000;

    // Fee maximum (i.e. 20%)
    uint256 public constant FEE_MAX = 200_000;

    // External token contracts
    ERC20 public immutable gmxBaseReward; // e.g. WETH (Ethereum)
    ERC20 public immutable gmx;
    ERC20 public immutable esGmx;

    // Pirex token contract(s) which are unlikely to change
    PxERC20 public immutable pxGmx;
    PxERC20 public immutable pxGlp;

    // Handles deposits to circumvent the GLP cooldown duration
    // to maintain a seamless deposit and redemption experience for users
    PirexGmxCooldownHandler public immutable pirexGmxCooldownHandler;

    // Pirex reward module contract
    address public immutable pirexRewards;

    // Snapshot vote delegation contract
    IDelegateRegistry public immutable delegateRegistry;

    // Pirex fee repository and distribution contract
    PirexFees public immutable pirexFees;

    // GMX contracts
    IRewardRouterV2 public gmxRewardRouterV2;
    IRewardRouterV2 public glpRewardRouterV2;
    RewardTracker public rewardTrackerGmx;
    RewardTracker public rewardTrackerGlp;
    RewardTracker public feeStakedGlp;
    RewardTracker public stakedGmx;
    IStakedGlp public stakedGlp;
    address public glpManager;
    IVault public gmxVault;

    // Migration related address
    address public migratedTo;

    // Snapshot space
    bytes32 public delegationSpace = bytes32("gmx.eth");

    // Fees (e.g. 5000 / 1000000 = 0.5%)
    mapping(Fees => uint256) public fees;

    event InitializeGmxState(
        address indexed caller,
        RewardTracker rewardTrackerGmx,
        RewardTracker rewardTrackerGlp,
        RewardTracker feeStakedGlp,
        RewardTracker stakedGmx,
        address glpManager,
        IVault gmxVault
    );
    event SetFee(Fees indexed f, uint256 fee);
    event SetContract(Contracts indexed c, address contractAddress);
    event DepositGmx(
        address indexed caller,
        address indexed receiver,
        uint256 deposited,
        uint256 postFeeAmount,
        uint256 feeAmount
    );
    event DepositGlp(
        address indexed receiver,
        uint256 deposited,
        uint256 postFeeAmount,
        uint256 feeAmount
    );
    event RedeemGlp(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 minOut,
        uint256 redemption,
        uint256 postFeeAmount,
        uint256 feeAmount
    );
    event ClaimRewards(
        uint256 baseRewards,
        uint256 esGmxRewards,
        uint256 gmxBaseRewards,
        uint256 glpBaseRewards,
        uint256 gmxEsGmxRewards,
        uint256 glpEsGmxRewards
    );
    event ClaimUserReward(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 rewardAmount,
        uint256 feeAmount
    );
    event InitiateMigration(address newContract);
    event CompleteMigration(address oldContract);
    event SetDelegationSpace(string delegationSpace, bool shouldClear);
    event SetVoteDelegate(address voteDelegate);
    event ClearVoteDelegate();

    error ZeroAmount();
    error ZeroAddress();
    error InvalidToken(address token);
    error NotPirexRewards();
    error InvalidFee();
    error EmptyString();
    error NotMigratedTo();
    error PendingMigration();

    /**
        @param  _pxGmx              address  PxGmx contract address
        @param  _pxGlp              address  PxGlp contract address
        @param  _pirexFees          address  PirexFees contract address
        @param  _pirexRewards       address  PirexRewards contract address
        @param  _delegateRegistry   address  Delegation registry contract address
        @param  _gmxBaseReward      address  GMX base reward token contract address
        @param  _gmx                address  GMX token contract address
        @param  _esGmx              address  esGMX token contract address
        @param  _gmxRewardRouterV2  address  GMX Reward Router contract address
        @param  _glpRewardRouterV2  address  GLP Reward Router contract address
        @param  _stakedGlp          address  Staked GLP token contract address
    */
    constructor(
        address _pxGmx,
        address _pxGlp,
        address _pirexFees,
        address _pirexRewards,
        address _delegateRegistry,
        address _gmxBaseReward,
        address _gmx,
        address _esGmx,
        address _gmxRewardRouterV2,
        address _glpRewardRouterV2,
        address _stakedGlp
    ) Owned(msg.sender) {
        // Start the contract paused, to ensure contract set is properly configured
        _pause();

        if (_pxGmx == address(0)) revert ZeroAddress();
        if (_pxGlp == address(0)) revert ZeroAddress();
        if (_pirexFees == address(0)) revert ZeroAddress();
        if (_pirexRewards == address(0)) revert ZeroAddress();
        if (_delegateRegistry == address(0)) revert ZeroAddress();
        if (_gmxBaseReward == address(0)) revert ZeroAddress();
        if (_gmx == address(0)) revert ZeroAddress();
        if (_esGmx == address(0)) revert ZeroAddress();
        if (_gmxRewardRouterV2 == address(0)) revert ZeroAddress();
        if (_glpRewardRouterV2 == address(0)) revert ZeroAddress();
        if (_stakedGlp == address(0)) revert ZeroAddress();

        pxGmx = PxERC20(_pxGmx);
        pxGlp = PxERC20(_pxGlp);
        pirexFees = PirexFees(_pirexFees);
        pirexGmxCooldownHandler = new PirexGmxCooldownHandler();
        pirexRewards = _pirexRewards;
        delegateRegistry = IDelegateRegistry(_delegateRegistry);
        gmxBaseReward = ERC20(_gmxBaseReward);
        gmx = ERC20(_gmx);
        esGmx = ERC20(_esGmx);
        gmxRewardRouterV2 = IRewardRouterV2(_gmxRewardRouterV2);
        glpRewardRouterV2 = IRewardRouterV2(_glpRewardRouterV2);
        stakedGlp = IStakedGlp(_stakedGlp);
    }

    modifier onlyPirexRewards() {
        if (msg.sender != pirexRewards) revert NotPirexRewards();
        _;
    }

    /**
        @notice Applied to depositFsGlp to enable PirexGmxCooldownHandler to
                call back and deposit minted + staked GLP on behalf of the user
    */
    modifier nonReentrantWithCooldownHandlerException() {
        require(
            msg.sender == address(pirexGmxCooldownHandler) || locked == 1,
            "REENTRANCY"
        );

        locked = 2;

        _;

        locked = 1;
    }

    /**
        @notice Compute post-fee asset and fee amounts from a fee type and total assets
        @param  f              enum     Fee
        @param  assets         uint256  GMX/GLP/WETH asset amount
        @return postFeeAmount  uint256  Post-fee asset amount (for mint/burn/claim/etc.)
        @return feeAmount      uint256  Fee amount
     */
    function _computeAssetAmounts(Fees f, uint256 assets)
        internal
        view
        returns (uint256 postFeeAmount, uint256 feeAmount)
    {
        feeAmount = (assets * fees[f]) / FEE_DENOMINATOR;
        postFeeAmount = assets - feeAmount;

        assert(feeAmount + postFeeAmount == assets);
    }

    /**
        @notice Calculate the base (e.g. WETH) or esGMX rewards for either GMX or GLP
        @param  isBaseReward  bool     Whether to calculate base or esGMX rewards
        @param  useGmx        bool     Whether the calculation should be for GMX
        @return               uint256  Amount of WETH/esGMX rewards
     */
    function _calculateRewards(bool isBaseReward, bool useGmx)
        internal
        view
        returns (uint256)
    {
        RewardTracker r;

        if (isBaseReward) {
            r = useGmx ? rewardTrackerGmx : rewardTrackerGlp;
        } else {
            r = useGmx ? stakedGmx : feeStakedGlp;
        }

        uint256 totalSupply = r.totalSupply();

        if (totalSupply == 0) return 0;

        address distributor = r.distributor();
        uint256 pendingRewards = IRewardDistributor(distributor)
            .pendingRewards();
        uint256 distributorBalance = (isBaseReward ? gmxBaseReward : esGmx)
            .balanceOf(distributor);
        uint256 blockReward = pendingRewards > distributorBalance
            ? distributorBalance
            : pendingRewards;
        uint256 precision = r.PRECISION();
        uint256 cumulativeRewardPerToken = r.cumulativeRewardPerToken() +
            ((blockReward * precision) / totalSupply);

        if (cumulativeRewardPerToken == 0) return 0;

        return
            r.claimableReward(address(this)) +
            ((r.stakedAmounts(address(this)) *
                (cumulativeRewardPerToken -
                    r.previousCumulatedRewardPerToken(address(this)))) /
                precision);
    }

    /**
        @notice Initialize GMX contract state
     */
    function initializeGmxState() external onlyOwner whenPaused {
        // Variables which can be assigned by reading previously-set GMX contracts
        rewardTrackerGmx = RewardTracker(gmxRewardRouterV2.feeGmxTracker());
        rewardTrackerGlp = RewardTracker(glpRewardRouterV2.feeGlpTracker());
        feeStakedGlp = RewardTracker(glpRewardRouterV2.stakedGlpTracker());
        stakedGmx = RewardTracker(gmxRewardRouterV2.stakedGmxTracker());
        glpManager = glpRewardRouterV2.glpManager();
        gmxVault = IGlpManager(glpManager).vault();

        emit InitializeGmxState(
            msg.sender,
            rewardTrackerGmx,
            rewardTrackerGlp,
            feeStakedGlp,
            stakedGmx,
            glpManager,
            gmxVault
        );

        // Approve GMX to enable staking
        gmx.safeApprove(address(stakedGmx), type(uint256).max);
    }

    /**
        @notice Set fee
        @param  f    enum     Fee
        @param  fee  uint256  Fee amount
     */
    function setFee(Fees f, uint256 fee) external onlyOwner {
        if (fee > FEE_MAX) revert InvalidFee();

        fees[f] = fee;

        emit SetFee(f, fee);
    }

    /**
        @notice Set a contract address
        @param  c                enum     Contracts
        @param  contractAddress  address  Contract address
     */
    function setContract(Contracts c, address contractAddress)
        external
        onlyOwner
    {
        if (contractAddress == address(0)) revert ZeroAddress();

        emit SetContract(c, contractAddress);

        if (c == Contracts.RewardRouterV2) {
            gmxRewardRouterV2 = IRewardRouterV2(contractAddress);
            return;
        }

        if (c == Contracts.GlpRewardRouterV2) {
            glpRewardRouterV2 = IRewardRouterV2(contractAddress);
            return;
        }

        if (c == Contracts.RewardTrackerGmx) {
            rewardTrackerGmx = RewardTracker(contractAddress);
            return;
        }

        if (c == Contracts.RewardTrackerGlp) {
            rewardTrackerGlp = RewardTracker(contractAddress);
            return;
        }

        if (c == Contracts.FeeStakedGlp) {
            feeStakedGlp = RewardTracker(contractAddress);
            return;
        }

        if (c == Contracts.StakedGmx) {
            // Set the current stakedGmx (pending change) approval amount to 0
            gmx.safeApprove(address(stakedGmx), 0);

            stakedGmx = RewardTracker(contractAddress);

            // Approve the new stakedGmx contract address allowance to the max
            gmx.safeApprove(contractAddress, type(uint256).max);
            return;
        }

        if (c == Contracts.StakedGlp) {
            stakedGlp = IStakedGlp(contractAddress);
            return;
        }

        if (c == Contracts.GmxVault) {
            gmxVault = IVault(contractAddress);
            return;
        }

        glpManager = contractAddress;
    }

    /**
        @notice Deposit GMX for pxGMX
        @param  amount         uint256  GMX amount
        @param  receiver       address  pxGMX receiver
        @return postFeeAmount  uint256  pxGMX minted for the receiver
        @return feeAmount      uint256  pxGMX distributed as fees
     */
    function depositGmx(uint256 amount, address receiver)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 postFeeAmount, uint256 feeAmount)
    {
        if (amount == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Transfer the caller's GMX to this contract and stake it for rewards
        gmx.safeTransferFrom(msg.sender, address(this), amount);
        gmxRewardRouterV2.stakeGmx(amount);

        // Get the pxGMX amounts for the receiver and the protocol (fees)
        (postFeeAmount, feeAmount) = _computeAssetAmounts(Fees.Deposit, amount);

        // Mint pxGMX for the receiver (excludes fees)
        pxGmx.mint(receiver, postFeeAmount);

        // Mint pxGMX for fee distribution contract
        if (feeAmount != 0) {
            pxGmx.mint(address(pirexFees), feeAmount);
        }

        emit DepositGmx(msg.sender, receiver, amount, postFeeAmount, feeAmount);
    }

    /**
        @notice Deposit fsGLP for pxGLP
        @param  amount         uint256  fsGLP amount
        @param  receiver       address  pxGLP receiver
        @return postFeeAmount  uint256  pxGLP minted for the receiver
        @return feeAmount      uint256  pxGLP distributed as fees
     */
    function depositFsGlp(uint256 amount, address receiver)
        external
        whenNotPaused
        nonReentrantWithCooldownHandlerException
        returns (uint256 postFeeAmount, uint256 feeAmount)
    {
        if (amount == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Transfer the caller's fsGLP (unstaked for the user, staked for this contract)
        stakedGlp.transferFrom(msg.sender, address(this), amount);

        // Get the pxGLP amounts for the receiver and the protocol (fees)
        (postFeeAmount, feeAmount) = _computeAssetAmounts(Fees.Deposit, amount);

        // Mint pxGLP for the receiver (excludes fees)
        pxGlp.mint(receiver, postFeeAmount);

        // Mint pxGLP for fee distribution contract
        if (feeAmount != 0) {
            pxGlp.mint(address(pirexFees), feeAmount);
        }

        emit DepositGlp(receiver, amount, postFeeAmount, feeAmount);
    }

    /**
        @notice Deposit GLP (minted with ETH) for pxGLP
        @param  minUsdg    uint256  Minimum USDG purchased and used to mint GLP
        @param  minGlp     uint256  Minimum GLP amount minted from ETH
        @param  receiver   address  pxGLP receiver
        @return            uint256  GLP minted + staked + deposited
        @return            uint256  pxGLP minted for the receiver
        @return            uint256  pxGLP distributed as fees
     */
    function depositGlpETH(
        uint256 minUsdg,
        uint256 minGlp,
        address receiver
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (msg.value == 0) revert ZeroAmount();
        if (minUsdg == 0) revert ZeroAmount();
        if (minGlp == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        return
            pirexGmxCooldownHandler.depositGlp{value: msg.value}(
                glpRewardRouterV2,
                stakedGlp,
                glpManager,
                address(0),
                msg.value,
                minUsdg,
                minGlp,
                receiver
            );
    }

    /**
        @notice Deposit GLP (minted with ERC20 tokens) for pxGLP
        @param  token        address  GMX-whitelisted token for minting GLP
        @param  tokenAmount  uint256  Whitelisted token amount
        @param  minUsdg      uint256  Minimum USDG purchased and used to mint GLP
        @param  minGlp       uint256  Minimum GLP amount minted from ERC20 tokens
        @param  receiver     address  pxGLP receiver
        @return              uint256  GLP minted + staked + deposited
        @return              uint256  pxGLP minted for the receiver
        @return              uint256  pxGLP distributed as fees
     */
    function depositGlp(
        address token,
        uint256 tokenAmount,
        uint256 minUsdg,
        uint256 minGlp,
        address receiver
    )
        external
        whenNotPaused
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (token == address(0)) revert ZeroAddress();
        if (tokenAmount == 0) revert ZeroAmount();
        if (minUsdg == 0) revert ZeroAmount();
        if (minGlp == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();
        if (!gmxVault.whitelistedTokens(token)) revert InvalidToken(token);

        ERC20(token).safeTransferFrom(
            msg.sender,
            address(pirexGmxCooldownHandler),
            tokenAmount
        );

        return
            pirexGmxCooldownHandler.depositGlp(
                glpRewardRouterV2,
                stakedGlp,
                glpManager,
                token,
                tokenAmount,
                minUsdg,
                minGlp,
                receiver
            );
    }

    /**
        @notice Redeem pxGLP
        @param  token          address  GMX-whitelisted token to be redeemed (optional)
        @param  amount         uint256  pxGLP amount
        @param  minOut         uint256  Minimum token output from GLP redemption
        @param  receiver       address  Output token recipient
        @return redeemed       uint256  Output tokens from redeeming GLP
        @return postFeeAmount  uint256  pxGLP burned from the msg.sender
        @return feeAmount      uint256  pxGLP distributed as fees
     */
    function _redeemPxGlp(
        address token,
        uint256 amount,
        uint256 minOut,
        address receiver
    )
        internal
        returns (
            uint256 redeemed,
            uint256 postFeeAmount,
            uint256 feeAmount
        )
    {
        if (amount == 0) revert ZeroAmount();
        if (minOut == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Calculate the post-fee and fee amounts based on the fee type and total amount
        (postFeeAmount, feeAmount) = _computeAssetAmounts(
            Fees.Redemption,
            amount
        );

        // Burn pxGLP before redeeming the underlying GLP
        pxGlp.burn(msg.sender, postFeeAmount);

        // Transfer pxGLP from caller to the fee distribution contract
        if (feeAmount != 0) {
            ERC20(pxGlp).safeTransferFrom(
                msg.sender,
                address(pirexFees),
                feeAmount
            );
        }

        // Unstake and redeem the underlying GLP for ERC20 tokens
        redeemed = token == address(0)
            ? glpRewardRouterV2.unstakeAndRedeemGlpETH(
                postFeeAmount,
                minOut,
                receiver
            )
            : glpRewardRouterV2.unstakeAndRedeemGlp(
                token,
                postFeeAmount,
                minOut,
                receiver
            );

        emit RedeemGlp(
            msg.sender,
            receiver,
            token,
            amount,
            minOut,
            redeemed,
            postFeeAmount,
            feeAmount
        );
    }

    /**
        @notice Redeem pxGLP for ETH from redeeming GLP
        @param  amount    uint256  pxGLP amount
        @param  minOut    uint256  Minimum ETH output from GLP redemption
        @param  receiver  address  ETH recipient
        @return           uint256  ETH redeemed from GLP
        @return           uint256  pxGLP burned from the msg.sender
        @return           uint256  pxGLP distributed as fees
     */
    function redeemPxGlpETH(
        uint256 amount,
        uint256 minOut,
        address receiver
    )
        external
        whenNotPaused
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return _redeemPxGlp(address(0), amount, minOut, receiver);
    }

    /**
        @notice Redeem pxGLP for ERC20 tokens from redeeming GLP
        @param  token     address  GMX-whitelisted token to be redeemed
        @param  amount    uint256  pxGLP amount
        @param  minOut    uint256  Minimum ERC20 output from GLP redemption
        @param  receiver  address  ERC20 token recipient
        @return           uint256  ERC20 tokens from redeeming GLP
        @return           uint256  pxGLP burned from the msg.sender
        @return           uint256  pxGLP distributed as fees
     */
    function redeemPxGlp(
        address token,
        uint256 amount,
        uint256 minOut,
        address receiver
    )
        external
        whenNotPaused
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (token == address(0)) revert ZeroAddress();
        if (!gmxVault.whitelistedTokens(token)) revert InvalidToken(token);

        return _redeemPxGlp(token, amount, minOut, receiver);
    }

    /**
        @notice Claim WETH/esGMX rewards + multiplier points (MP)
        @return producerTokens  ERC20[]    Producer tokens (pxGLP and pxGMX)
        @return rewardTokens    ERC20[]    Reward token contract instances
        @return rewardAmounts   uint256[]  Reward amounts from each producerToken
     */
    function claimRewards()
        external
        onlyPirexRewards
        returns (
            ERC20[] memory producerTokens,
            ERC20[] memory rewardTokens,
            uint256[] memory rewardAmounts
        )
    {
        // Assign return values used by the PirexRewards contract
        producerTokens = new ERC20[](4);
        rewardTokens = new ERC20[](4);
        rewardAmounts = new uint256[](4);
        producerTokens[0] = pxGmx;
        producerTokens[1] = pxGlp;
        producerTokens[2] = pxGmx;
        producerTokens[3] = pxGlp;
        rewardTokens[0] = gmxBaseReward;
        rewardTokens[1] = gmxBaseReward;
        rewardTokens[2] = ERC20(pxGmx); // esGMX rewards distributed as pxGMX
        rewardTokens[3] = ERC20(pxGmx);

        // Get pre-reward claim reward token balances to calculate actual amount received
        uint256 baseRewardBeforeClaim = gmxBaseReward.balanceOf(address(this));
        uint256 esGmxBeforeClaim = stakedGmx.depositBalances(
            address(this),
            address(esGmx)
        );

        // Calculate the unclaimed reward token amounts produced for each token type
        uint256 gmxBaseRewards = _calculateRewards(true, true);
        uint256 glpBaseRewards = _calculateRewards(true, false);
        uint256 gmxEsGmxRewards = _calculateRewards(false, true);
        uint256 glpEsGmxRewards = _calculateRewards(false, false);

        // Claim and stake esGMX + MP, and claim WETH
        gmxRewardRouterV2.handleRewards(
            false,
            false,
            true,
            true,
            true,
            true,
            false
        );

        uint256 baseRewards = gmxBaseReward.balanceOf(address(this)) -
            baseRewardBeforeClaim;
        uint256 esGmxRewards = stakedGmx.depositBalances(
            address(this),
            address(esGmx)
        ) - esGmxBeforeClaim;

        if (baseRewards != 0) {
            // This may not be necessary and is more of a hedge against a discrepancy between
            // the actual rewards and the calculated amounts. Needs further consideration
            rewardAmounts[0] =
                (gmxBaseRewards * baseRewards) /
                (gmxBaseRewards + glpBaseRewards);
            rewardAmounts[1] = baseRewards - rewardAmounts[0];
        }

        if (esGmxRewards != 0) {
            rewardAmounts[2] =
                (gmxEsGmxRewards * esGmxRewards) /
                (gmxEsGmxRewards + glpEsGmxRewards);
            rewardAmounts[3] = esGmxRewards - rewardAmounts[2];
        }

        emit ClaimRewards(
            baseRewards,
            esGmxRewards,
            gmxBaseRewards,
            glpBaseRewards,
            gmxEsGmxRewards,
            glpEsGmxRewards
        );
    }

    /**
        @notice Mint/transfer the specified reward token to the receiver
        @param  token     address  Reward token address
        @param  amount    uint256  Reward amount
        @param  receiver  address  Reward receiver
     */
    function claimUserReward(
        address token,
        uint256 amount,
        address receiver
    )
        external
        onlyPirexRewards
        returns (uint256 postFeeAmount, uint256 feeAmount)
    {
        if (token == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        (postFeeAmount, feeAmount) = _computeAssetAmounts(Fees.Reward, amount);

        if (token == address(pxGmx)) {
            // Mint pxGMX for the user - the analog for esGMX rewards
            pxGmx.mint(receiver, postFeeAmount);

            if (feeAmount != 0) pxGmx.mint(address(pirexFees), feeAmount);
        } else if (token == address(gmxBaseReward)) {
            gmxBaseReward.safeTransfer(receiver, postFeeAmount);

            if (feeAmount != 0)
                gmxBaseReward.safeTransfer(address(pirexFees), feeAmount);
        }

        emit ClaimUserReward(receiver, token, amount, postFeeAmount, feeAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        VOTE DELEGATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Set delegationSpace
        @param  _delegationSpace  string  Snapshot delegation space
        @param  shouldClear       bool    Whether to clear the vote delegate for the current space
     */
    function setDelegationSpace(
        string memory _delegationSpace,
        bool shouldClear
    ) external onlyOwner {
        if (shouldClear) {
            // Clear the delegation for the current delegation space
            clearVoteDelegate();
        }

        bytes memory d = bytes(_delegationSpace);

        if (d.length == 0) revert EmptyString();

        delegationSpace = bytes32(d);

        emit SetDelegationSpace(_delegationSpace, shouldClear);
    }

    /**
        @notice Set vote delegate
        @param  voteDelegate  address  Account to delegate votes to
     */
    function setVoteDelegate(address voteDelegate) external onlyOwner {
        if (voteDelegate == address(0)) revert ZeroAddress();

        emit SetVoteDelegate(voteDelegate);

        delegateRegistry.setDelegate(delegationSpace, voteDelegate);
    }

    /**
        @notice Clear vote delegate
     */
    function clearVoteDelegate() public onlyOwner {
        emit ClearVoteDelegate();

        delegateRegistry.clearDelegate(delegationSpace);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY/MIGRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Set the contract's pause state
        @param state  bool  Pause state
    */
    function setPauseState(bool state) external onlyOwner {
        if (state) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
        @notice Initiate contract migration (called by the old contract)
        @param  newContract  address  Address of the new contract
    */
    function initiateMigration(address newContract)
        external
        whenPaused
        onlyOwner
    {
        if (newContract == address(0)) revert ZeroAddress();

        // Notify the reward router that the current/old contract is going to perform
        // full account transfer to the specified new contract
        gmxRewardRouterV2.signalTransfer(newContract);

        migratedTo = newContract;

        emit InitiateMigration(newContract);
    }

    /**
        @notice Migrate remaining (base) reward to the new contract after completing migration
    */
    function migrateReward() external whenPaused {
        if (msg.sender != migratedTo) revert NotMigratedTo();
        if (gmxRewardRouterV2.pendingReceivers(address(this)) != address(0))
            revert PendingMigration();

        // Transfer out any remaining base reward (ie. WETH) to the new contract
        gmxBaseReward.safeTransfer(
            migratedTo,
            gmxBaseReward.balanceOf(address(this))
        );
    }

    /**
        @notice Complete contract migration (called by the new contract)
        @param  oldContract  address  Address of the old contract
    */
    function completeMigration(address oldContract)
        external
        whenPaused
        onlyOwner
    {
        if (oldContract == address(0)) revert ZeroAddress();

        // Claim GMX rewards before the account transfer
        IPirexRewards(pirexRewards).accrueStrategy();

        // Complete the full account transfer process
        gmxRewardRouterV2.acceptTransfer(oldContract);

        // Perform reward token transfer from the old contract to the new one
        PirexGmx(oldContract).migrateReward();

        emit CompleteMigration(oldContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IPirexGmx} from "src/interfaces/IPirexGmx.sol";

/**
    Originally inspired by and utilizes Fei Protocol's Flywheel V2 accrual logic
    (thank you Tribe team):
    https://github.com/fei-protocol/flywheel-v2/blob/dbe3cb8/src/FlywheelCore.sol
*/
contract PirexRewards is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using FixedPointMathLib for uint256;

    struct User {
        // User indexes by strategy
        mapping(bytes => uint256) index;
        // Accrued but not yet transferred rewards
        mapping(ERC20 => uint256) rewardsAccrued;
        // Accounts which users are forwarding their rewards to
        mapping(ERC20 => address) rewardRecipients;
    }

    // The fixed point factor
    uint256 public constant ONE = 1e18;

    // Core reward-producing Pirex contract
    IPirexGmx public producer;

    // Strategies by producer token
    mapping(ERC20 => bytes[]) public strategies;

    // Strategy indexes
    mapping(bytes => uint256) public strategyIndexes;

    // User data
    mapping(address => User) internal users;

    event SetProducer(address producer);
    event AddStrategy(bytes indexed newStrategy);
    event Claim(
        ERC20 indexed rewardToken,
        address indexed user,
        address indexed recipient,
        uint256 amount
    );
    event SetRewardRecipient(
        address indexed user,
        ERC20 indexed rewardToken,
        address indexed recipient
    );
    event UnsetRewardRecipient(address indexed user, ERC20 indexed rewardToken);
    event AccrueStrategy(
        ERC20[] producerTokens,
        ERC20[] rewardTokens,
        uint256[] rewardAmounts
    );
    event AccrueUser(
        ERC20 indexed producerToken,
        address indexed user,
        bytes[] strategy
    );

    error StrategyAlreadySet();
    error ZeroAddress();
    error EmptyArray();
    error NotContract();

    constructor() {
        // Best practice to prevent the implementation contract from being initialized
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    /**
        @notice Get strategies for a producer token
        @param  producerToken  ERC20    Producer token contract
        @return                bytes[]  Strategies list
     */
    function getStrategies(ERC20 producerToken)
        external
        view
        returns (bytes[] memory)
    {
        return strategies[producerToken];
    }

    /**
        @notice Get a strategy index for a user
        @param  user      address  User
        @param  strategy  bytes    Strategy (abi-encoded producer and reward tokens)
     */
    function getUserIndex(address user, bytes memory strategy)
        external
        view
        returns (uint256)
    {
        return users[user].index[strategy];
    }

    /**
        @notice Get the rewards accrued for a user
        @param  user         address  User
        @param  rewardToken  ERC20    Reward token contract
     */
    function getUserRewardsAccrued(address user, ERC20 rewardToken)
        external
        view
        returns (uint256)
    {
        return users[user].rewardsAccrued[rewardToken];
    }

    /**
        @notice Set producer
        @param  _producer  address  Producer contract address
     */
    function setProducer(address _producer) external onlyOwner {
        if (_producer == address(0)) revert ZeroAddress();

        producer = IPirexGmx(_producer);

        emit SetProducer(_producer);
    }

    /**
        @notice Add a strategy comprised of a producer and reward token
        @param  producerToken  ERC20  Producer token contract
        @param  rewardToken    ERC20  Reward token contract
        @return strategy       bytes  Strategy
    */
    function addStrategyForRewards(ERC20 producerToken, ERC20 rewardToken)
        external
        onlyOwner
        returns (bytes memory)
    {
        if (address(producerToken) == address(0)) revert ZeroAddress();
        if (address(rewardToken) == address(0)) revert ZeroAddress();

        bytes memory strategy = abi.encode(producerToken, rewardToken);

        if (strategyIndexes[strategy] != 0) revert StrategyAlreadySet();

        strategies[producerToken].push(strategy);

        strategyIndexes[strategy] = ONE;

        emit AddStrategy(strategy);

        return strategy;
    }

    /**
        @notice Accrue strategy rewards
        @return producerTokens  ERC20[]    Producer token contracts
        @return rewardTokens    ERC20[]    Reward token contracts
        @return rewardAmounts   uint256[]  Reward token amounts
    */
    function accrueStrategy()
        public
        returns (
            ERC20[] memory producerTokens,
            ERC20[] memory rewardTokens,
            uint256[] memory rewardAmounts
        )
    {
        // pxGMX and pxGLP rewards must be claimed all at once since PirexGmx is
        // the sole token holder
        (producerTokens, rewardTokens, rewardAmounts) = producer.claimRewards();

        uint256 pLen = producerTokens.length;

        // Iterate over the producer tokens and accrue their strategies
        for (uint256 i; i < pLen; ) {
            uint256 accruedRewards = rewardAmounts[i];

            // Only run strategy accrual logic if there are rewards
            if (accruedRewards != 0) {
                ERC20 producerToken = producerTokens[i];

                // Accumulate rewards per token onto the index, multiplied by fixed-point factor
                strategyIndexes[
                    // Get the strategy (mapping key) by encoding the producer and reward tokens
                    abi.encode(producerToken, rewardTokens[i])
                ] += accruedRewards.mulDivDown(
                    ONE,
                    producerToken.totalSupply()
                );
            }

            // Not possible to overflow since `i` is bound by the length of `producerTokens`
            unchecked {
                ++i;
            }
        }

        emit AccrueStrategy(producerTokens, rewardTokens, rewardAmounts);
    }

    /**
        @notice Accrue user rewards for a producer token's strategies
        @param  producerToken  ERC20    Producer token contract
        @param  user           address  User
    */
    function accrueUser(ERC20 producerToken, address user) public {
        if (address(producerToken) == address(0)) revert ZeroAddress();
        if (user == address(0)) revert ZeroAddress();

        bytes[] memory s = strategies[producerToken];
        uint256 sLen = s.length;

        if (sLen == 0) revert EmptyArray();

        User storage u = users[user];
        uint256 producerTokenBalance = producerToken.balanceOf(user);

        // Accrue user rewards for each strategy (producer and reward token pair)
        for (uint256 i; i < sLen; ) {
            bytes memory strategy = s[i];

            // Load indices
            uint256 strategyIndex = strategyIndexes[strategy];
            uint256 supplierIndex = u.index[strategy];

            // Sync user index to global
            u.index[strategy] = strategyIndex;

            // If user hasn't yet accrued rewards, grant them interest from the strategy beginning if they have a balance
            // Zero balances will have no effect other than syncing to global index
            if (supplierIndex == 0) {
                supplierIndex = ONE;
            }

            (, ERC20 rewardToken) = abi.decode(strategy, (ERC20, ERC20));

            // Accumulate rewards by multiplying user tokens by rewardsPerToken index and adding on unclaimed
            u.rewardsAccrued[rewardToken] += producerTokenBalance.mulDivDown(
                strategyIndex - supplierIndex,
                ONE
            );

            // Not possible to overflow since `i` is bound by the length of the producer token's stored strategies
            unchecked {
                ++i;
            }
        }

        emit AccrueUser(producerToken, user, s);
    }

    /**
      @notice Claim rewards for a given user
      @param  rewardTokens  ERC20[]    Reward token contracts
      @param  user          address    The user claiming rewards
      @return claimed       uint256[]  Claimed rewards
    */
    function _claim(ERC20[] memory rewardTokens, address user)
        private
        returns (
            uint256[] memory claimed,
            uint256[] memory postFeeAmounts,
            uint256[] memory feeAmounts
        )
    {
        uint256 rLen = rewardTokens.length;
        User storage u = users[user];
        claimed = new uint256[](rLen);
        postFeeAmounts = new uint256[](rLen);
        feeAmounts = new uint256[](rLen);

        for (uint256 i; i < rLen; ) {
            ERC20 r = rewardTokens[i];
            claimed[i] = u.rewardsAccrued[r];

            if (claimed[i] != 0) {
                u.rewardsAccrued[r] = 0;

                // Forward rewards if a rewardRecipient is set
                address rewardRecipient = u.rewardRecipients[r];
                address recipient = rewardRecipient == address(0)
                    ? user
                    : rewardRecipient;

                (uint256 postFeeAmount, uint256 feeAmount) = producer
                    .claimUserReward(address(r), claimed[i], recipient);
                postFeeAmounts[i] = postFeeAmount;
                feeAmounts[i] = feeAmount;

                emit Claim(r, user, recipient, claimed[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
      @notice Claim rewards for a given user
      @param  rewardTokens  ERC20[]    Reward token contracts
      @param  user          address    The user claiming rewards
      @return               uint256[]  Claimed rewards
    */
    function claim(ERC20[] memory rewardTokens, address user)
        external
        nonReentrant
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        if (rewardTokens.length == 0) revert EmptyArray();
        if (user == address(0)) revert ZeroAddress();

        return _claim(rewardTokens, user);
    }

    /**
      @notice Accrue rewards and claim them for a given user
      @param  user            address    The user claiming rewards
      @return producerTokens  ERC20[]    Producer token contracts
      @return rewardTokens    ERC20[]    Reward token contracts
      @return rewardAmounts   uint256[]  Reward token amounts
      @return claimed         uint256[]  Claimed rewards
    */
    function accrueAndClaim(address user)
        external
        nonReentrant
        returns (
            ERC20[] memory producerTokens,
            ERC20[] memory rewardTokens,
            uint256[] memory rewardAmounts,
            uint256[] memory claimed,
            uint256[] memory postFeeAmounts,
            uint256[] memory feeAmounts
        )
    {
        if (user == address(0)) revert ZeroAddress();

        // Harvest and accrue strategy indexes to ensure the rewards are up-to-date
        (producerTokens, rewardTokens, rewardAmounts) = accrueStrategy();

        uint256 pLen = producerTokens.length;

        for (uint256 i; i < pLen; ) {
            // Accrue rewards for every producer token in preparation for the claim
            accrueUser(producerTokens[i], user);

            unchecked {
                ++i;
            }
        }

        // Claim the producer token's reward tokens
        (claimed, postFeeAmounts, feeAmounts) = _claim(rewardTokens, user);
    }

    /**
        @notice Get the reward recipient for a user by producer and reward token
        @param  user         address  User
        @param  rewardToken  ERC20    Reward token contract
        @return              address  Reward recipient
    */
    function getRewardRecipient(address user, ERC20 rewardToken)
        external
        view
        returns (address)
    {
        return users[user].rewardRecipients[rewardToken];
    }

    /**
        @notice Set reward recipient for a reward token
        @param  rewardToken  ERC20    Reward token contract
        @param  recipient    address  Rewards recipient
    */
    function setRewardRecipient(ERC20 rewardToken, address recipient) external {
        if (address(rewardToken) == address(0)) revert ZeroAddress();
        if (recipient == address(0)) revert ZeroAddress();

        users[msg.sender].rewardRecipients[rewardToken] = recipient;

        emit SetRewardRecipient(msg.sender, rewardToken, recipient);
    }

    /**
        @notice Unset reward recipient for a reward token
        @param  rewardToken  ERC20  Reward token contract
    */
    function unsetRewardRecipient(ERC20 rewardToken) external {
        if (address(rewardToken) == address(0)) revert ZeroAddress();

        delete users[msg.sender].rewardRecipients[rewardToken];

        emit UnsetRewardRecipient(msg.sender, rewardToken);
    }

    /*//////////////////////////////////////////////////////////////
                    ⚠️ NOTABLE PRIVILEGED METHODS ⚠️
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Privileged method for setting the reward recipient of a contract
        @notice This should ONLY be used to forward rewards for Pirex-GMX LP contracts
        @notice In production, we will have a 2nd multisig which reduces risk of abuse
        @param  lpContract   address  Pirex-GMX LP contract
        @param  rewardToken  ERC20    Reward token contract
        @param  recipient    address  Rewards recipient
    */
    function setRewardRecipientPrivileged(
        address lpContract,
        ERC20 rewardToken,
        address recipient
    ) external onlyOwner {
        if (lpContract.code.length == 0) revert NotContract();
        if (address(rewardToken) == address(0)) revert ZeroAddress();
        if (recipient == address(0)) revert ZeroAddress();

        users[lpContract].rewardRecipients[rewardToken] = recipient;

        emit SetRewardRecipient(lpContract, rewardToken, recipient);
    }

    /**
        @notice Privileged method for unsetting the reward recipient of a contract
        @param  lpContract   address  Pirex-GMX LP contract
        @param  rewardToken  ERC20    Reward token contract
    */
    function unsetRewardRecipientPrivileged(
        address lpContract,
        ERC20 rewardToken
    ) external onlyOwner {
        if (lpContract.code.length == 0) revert NotContract();
        if (address(rewardToken) == address(0)) revert ZeroAddress();

        delete users[lpContract].rewardRecipients[rewardToken];

        emit UnsetRewardRecipient(lpContract, rewardToken);
    }

    // Storage gaps for reserving storage slots for future upgrades
    uint256[10000] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface ICamelotRouter {
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory);

    function getPair(
        address token1,
        address token2
    ) external view returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPirexGmxDepositRouter {
    /**
     * @notice Deposit GMX for pxGMX
     * @dev Try to swap GMX for WETH on UniswapV3, then swap WETH for pxGMX on Camelot
     *     If unsuccessful deposit GMX for pxGMX on PirexGmx
     *  @param  amount         uint256  GMX amount
     *  @param  receiver       address  pxGMX receiver
     *  @return amountOut      uint256  pxGMX minted for the receiver
     *  @return feeAmount      uint256  pxGMX distributed as fees
     */
    function depositGmx(uint256 amount, address receiver)
        external
        returns (uint256 amountOut, uint256 feeAmount);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/**
    @notice Modified visibility of `locked` variable from private to internal
 */
/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 internal locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {PirexRewards} from "src/PirexRewards.sol";

contract PxERC20 is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    PirexRewards public immutable pirexRewards;

    error ZeroAddress();
    error ZeroAmount();
    error EmptyString();

    /**
        @param  _pirexRewards  address  PirexRewards contract address
        @param  _name          string   Token name (e.g. Pirex GLP)
        @param  _symbol        string   Token symbol (e.g. pxGLP)
        @param  _decimals      uint8    Token decimals (e.g. 18)
    */
    constructor(
        address _pirexRewards,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        if (_pirexRewards == address(0)) revert ZeroAddress();
        if (bytes(_name).length == 0) revert EmptyString();
        if (bytes(_symbol).length == 0) revert EmptyString();
        if (_decimals == 0) revert ZeroAmount();

        pirexRewards = PirexRewards(_pirexRewards);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Mint tokens
        @param  to      address  Token recipient
        @param  amount  uint256  Token mint amount
    */
    function mint(address to, uint256 amount)
        external
        virtual
        onlyRole(MINTER_ROLE)
    {
        // Update delta for strategies prior to supply change
        pirexRewards.accrueStrategy();

        // Update delta for strategies prior to balance change
        pirexRewards.accrueUser(this, to);

        _mint(to, amount);
    }

    /**
        @notice Burn tokens
        @param  from    address  Token owner
        @param  amount  uint256  Token burn amount
    */
    function burn(address from, uint256 amount)
        external
        virtual
        onlyRole(BURNER_ROLE)
    {
        pirexRewards.accrueStrategy();
        pirexRewards.accrueUser(this, from);

        _burn(from, amount);
    }

    /**
        @notice Transfer tokens (called by token owner)
        @param  to      address  Token recipient
        @param  amount  uint256  Token transfer amount
        @return         bool     Token transfer status
    */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        // Update delta for strategies so that users receive all rewards up to the transfers
        // Accrue users prior to balance changes to ensure that they receive their entitled rewards
        pirexRewards.accrueStrategy();
        pirexRewards.accrueUser(this, msg.sender);
        pirexRewards.accrueUser(this, to);

        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /**
        @notice Transfer tokens (called by account with allowance)
        @param  from    address  Token owner
        @param  to      address  Token recipient
        @param  amount  uint256  Token transfer amount
        @return         bool     Token transfer status
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        pirexRewards.accrueStrategy();
        pirexRewards.accrueUser(this, from);
        pirexRewards.accrueUser(this, to);

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract PirexFees {
    using SafeTransferLib for ERC20;

    // Denominator used when calculating the fee distribution percent
    // E.g. if the treasuryFeePercent were set to 50, then the treasury's
    // percent share of the fee distribution would be 50% (50 / 100)
    uint8 public constant FEE_PERCENT_DENOMINATOR = 100;

    // Maximum treasury fee percent
    uint8 public constant MAX_TREASURY_FEE_PERCENT = 75;

    // Multisig addresses which have the ability to set the fee recipient addresses
    // The treasuryManager also has the ability to update treasuryFeePercent
    address public immutable treasuryManager;
    address public immutable contributorsManager;

    // Configurable treasury percent share of fees (default is max)
    // Currently, there are only two fee recipients, so we only need to
    // store the percent of one recipient to derive the other
    uint8 public treasuryFeePercent = MAX_TREASURY_FEE_PERCENT;

    // Configurable fee recipient addresses
    address public treasury;
    address public contributors;

    event SetTreasury(address _treasury);
    event SetContributors(address _contributors);
    event SetTreasuryFeePercent(uint8 _treasuryFeePercent);
    event DistributeFees(
        ERC20 indexed token,
        uint256 distribution,
        uint256 treasuryDistribution,
        uint256 contributorsDistribution
    );

    error ZeroAddress();
    error Unauthorized();
    error InvalidFeePercent();

    /**
        @param  _treasury             address  Redacted treasury
        @param  _contributors         address  Pirex contributor distribution contract
        @param  _treasuryManager      address  Redacted treasury manager (multisig)
        @param  _contributorsManager  address  Pirex contributor manager (multisig)
     */
    constructor(
        address _treasury,
        address _contributors,
        address _treasuryManager,
        address _contributorsManager
    ) {
        if (_treasury == address(0)) revert ZeroAddress();
        if (_contributors == address(0)) revert ZeroAddress();
        if (_treasuryManager == address(0)) revert ZeroAddress();
        if (_contributorsManager == address(0)) revert ZeroAddress();

        treasury = _treasury;
        contributors = _contributors;
        treasuryManager = _treasuryManager;
        contributorsManager = _contributorsManager;
    }

    /**
        @notice Update the treasury address
        @param  _treasury  address  Fee recipient address
     */
    function setTreasury(address _treasury) external {
        if (msg.sender != treasuryManager) revert Unauthorized();
        if (_treasury == address(0)) revert ZeroAddress();

        treasury = _treasury;

        emit SetTreasury(_treasury);
    }

    /**
        @notice Update the contributors address
        @param  _contributors  address  Fee recipient address
     */
    function setContributors(address _contributors) external {
        if (msg.sender != contributorsManager) revert Unauthorized();
        if (_contributors == address(0)) revert ZeroAddress();

        contributors = _contributors;

        emit SetContributors(_contributors);
    }

    /**
        @notice Set treasury fee percent
        @param  _treasuryFeePercent  uint8  Treasury fee percent
     */
    function setTreasuryFeePercent(uint8 _treasuryFeePercent) external {
        if (msg.sender != treasuryManager) revert Unauthorized();

        // Treasury fee percent should never exceed the pre-configured max
        if (_treasuryFeePercent > MAX_TREASURY_FEE_PERCENT)
            revert InvalidFeePercent();

        treasuryFeePercent = _treasuryFeePercent;

        emit SetTreasuryFeePercent(_treasuryFeePercent);
    }

    /**
        @notice Distribute fees
        @param  token  address  Fee token
     */
    function distributeFees(ERC20 token) external {
        uint256 distribution = token.balanceOf(address(this));
        uint256 treasuryDistribution = (distribution * treasuryFeePercent) /
            FEE_PERCENT_DENOMINATOR;
        uint256 contributorsDistribution = distribution - treasuryDistribution;

        emit DistributeFees(
            token,
            distribution,
            treasuryDistribution,
            contributorsDistribution
        );

        // Favoring push over pull to reduce accounting complexity for different tokens
        token.safeTransfer(treasury, treasuryDistribution);
        token.safeTransfer(contributors, contributorsDistribution);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
contract ReentrancyGuard {
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IRewardDistributor {
    function rewardToken() external view returns (address);

    function tokensPerInterval() external view returns (uint256);

    function pendingRewards() external view returns (uint256);

    function distribute() external returns (uint256);
}

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken)
        external
        returns (uint256);

    function stakedAmounts(address _account) external returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver)
        external
        returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account)
        external
        view
        returns (uint256);

    function cumulativeRewards(address _account)
        external
        view
        returns (uint256);
}

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

contract RewardTracker is IERC20, ReentrancyGuard, IRewardTracker, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRECISION = 1e30;

    uint8 public constant decimals = 18;

    bool public isInitialized;

    string public name;
    string public symbol;

    address public distributor;
    mapping(address => bool) public isDepositToken;
    mapping(address => mapping(address => uint256))
        public
        override depositBalances;

    uint256 public override totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    uint256 public cumulativeRewardPerToken;
    mapping(address => uint256) public override stakedAmounts;
    mapping(address => uint256) public claimableReward;
    mapping(address => uint256) public previousCumulatedRewardPerToken;
    mapping(address => uint256) public override cumulativeRewards;
    mapping(address => uint256) public override averageStakedAmounts;

    bool public inPrivateTransferMode;
    bool public inPrivateStakingMode;
    bool public inPrivateClaimingMode;
    mapping(address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function initialize(address[] memory _depositTokens, address _distributor)
        external
        onlyGov
    {
        require(!isInitialized, "RewardTracker: already initialized");
        isInitialized = true;

        for (uint256 i = 0; i < _depositTokens.length; i++) {
            address depositToken = _depositTokens[i];
            isDepositToken[depositToken] = true;
        }

        distributor = _distributor;
    }

    function setDepositToken(address _depositToken, bool _isDepositToken)
        external
        onlyGov
    {
        isDepositToken[_depositToken] = _isDepositToken;
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode)
        external
        onlyGov
    {
        inPrivateTransferMode = _inPrivateTransferMode;
    }

    function setInPrivateStakingMode(bool _inPrivateStakingMode)
        external
        onlyGov
    {
        inPrivateStakingMode = _inPrivateStakingMode;
    }

    function setInPrivateClaimingMode(bool _inPrivateClaimingMode)
        external
        onlyGov
    {
        inPrivateClaimingMode = _inPrivateClaimingMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        require(
            !isDepositToken[_token],
            "RewardTracker: _token cannot be a depositToken"
        );
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return balances[_account];
    }

    function stake(address _depositToken, uint256 _amount)
        external
        override
        nonReentrant
    {
        if (inPrivateStakingMode) {
            revert("RewardTracker: action not enabled");
        }
        _stake(msg.sender, msg.sender, _depositToken, _amount);
    }

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external override nonReentrant {
        _validateHandler();
        _stake(_fundingAccount, _account, _depositToken, _amount);
    }

    function unstake(address _depositToken, uint256 _amount)
        external
        override
        nonReentrant
    {
        if (inPrivateStakingMode) {
            revert("RewardTracker: action not enabled");
        }
        _unstake(msg.sender, _depositToken, _amount, msg.sender);
    }

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external override nonReentrant {
        _validateHandler();
        _unstake(_account, _depositToken, _amount, _receiver);
    }

    function transfer(address _recipient, uint256 _amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }

        uint256 nextAllowance = allowances[_sender][msg.sender].sub(
            _amount,
            "RewardTracker: transfer amount exceeds allowance"
        );
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function tokensPerInterval() external view override returns (uint256) {
        return IRewardDistributor(distributor).tokensPerInterval();
    }

    function updateRewards() external override nonReentrant {
        _updateRewards(address(0));
    }

    function claim(address _receiver)
        external
        override
        nonReentrant
        returns (uint256)
    {
        if (inPrivateClaimingMode) {
            revert("RewardTracker: action not enabled");
        }
        return _claim(msg.sender, _receiver);
    }

    function claimForAccount(address _account, address _receiver)
        external
        override
        nonReentrant
        returns (uint256)
    {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    function claimable(address _account)
        public
        view
        override
        returns (uint256)
    {
        uint256 stakedAmount = stakedAmounts[_account];
        if (stakedAmount == 0) {
            return claimableReward[_account];
        }
        uint256 supply = totalSupply;
        uint256 pendingRewards = IRewardDistributor(distributor)
            .pendingRewards()
            .mul(PRECISION);
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken.add(
            pendingRewards.div(supply)
        );
        return
            claimableReward[_account].add(
                stakedAmount
                    .mul(
                        nextCumulativeRewardPerToken.sub(
                            previousCumulatedRewardPerToken[_account]
                        )
                    )
                    .div(PRECISION)
            );
    }

    function rewardToken() public view returns (address) {
        return IRewardDistributor(distributor).rewardToken();
    }

    function _claim(address _account, address _receiver)
        private
        returns (uint256)
    {
        _updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken()).safeTransfer(_receiver, tokenAmount);
            emit Claim(_account, tokenAmount);
        }

        return tokenAmount;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(
            _account != address(0),
            "RewardTracker: mint to the zero address"
        );

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(
            _account != address(0),
            "RewardTracker: burn from the zero address"
        );

        balances[_account] = balances[_account].sub(
            _amount,
            "RewardTracker: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(
            _sender != address(0),
            "RewardTracker: transfer from the zero address"
        );
        require(
            _recipient != address(0),
            "RewardTracker: transfer to the zero address"
        );

        if (inPrivateTransferMode) {
            _validateHandler();
        }

        balances[_sender] = balances[_sender].sub(
            _amount,
            "RewardTracker: transfer amount exceeds balance"
        );
        balances[_recipient] = balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(
            _owner != address(0),
            "RewardTracker: approve from the zero address"
        );
        require(
            _spender != address(0),
            "RewardTracker: approve to the zero address"
        );

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "RewardTracker: forbidden");
    }

    function _stake(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(
            isDepositToken[_depositToken],
            "RewardTracker: invalid _depositToken"
        );

        IERC20(_depositToken).safeTransferFrom(
            _fundingAccount,
            address(this),
            _amount
        );

        _updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
        depositBalances[_account][_depositToken] = depositBalances[_account][
            _depositToken
        ].add(_amount);

        _mint(_account, _amount);
    }

    function _unstake(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(
            isDepositToken[_depositToken],
            "RewardTracker: invalid _depositToken"
        );

        _updateRewards(_account);

        uint256 stakedAmount = stakedAmounts[_account];
        require(
            stakedAmounts[_account] >= _amount,
            "RewardTracker: _amount exceeds stakedAmount"
        );

        stakedAmounts[_account] = stakedAmount.sub(_amount);

        uint256 depositBalance = depositBalances[_account][_depositToken];
        require(
            depositBalance >= _amount,
            "RewardTracker: _amount exceeds depositBalance"
        );
        depositBalances[_account][_depositToken] = depositBalance.sub(_amount);

        _burn(_account, _amount);
        IERC20(_depositToken).safeTransfer(_receiver, _amount);
    }

    function _updateRewards(address _account) private {
        uint256 blockReward = IRewardDistributor(distributor).distribute();

        uint256 supply = totalSupply;
        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(
                blockReward.mul(PRECISION).div(supply)
            );
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedAmount = stakedAmounts[_account];
            uint256 accountReward = stakedAmount
                .mul(
                    _cumulativeRewardPerToken.sub(
                        previousCumulatedRewardPerToken[_account]
                    )
                )
                .div(PRECISION);
            uint256 _claimableReward = claimableReward[_account].add(
                accountReward
            );

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[
                _account
            ] = _cumulativeRewardPerToken;

            if (_claimableReward > 0 && stakedAmounts[_account] > 0) {
                uint256 nextCumulativeReward = cumulativeRewards[_account].add(
                    accountReward
                );

                averageStakedAmounts[_account] = averageStakedAmounts[_account]
                    .mul(cumulativeRewards[_account])
                    .div(nextCumulativeReward)
                    .add(
                        stakedAmount.mul(accountReward).div(
                            nextCumulativeReward
                        )
                    );

                cumulativeRewards[_account] = nextCumulativeReward;
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://arbiscan.io/address/0xa906f338cb21815cbc4bc87ace9e68c87ef8d8f1#code
interface IRewardRouterV2 {
    function stakeGmx(uint256 _amount) external;

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp)
        external
        payable
        returns (uint256);

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function signalTransfer(address _receiver) external;

    function acceptTransfer(address _sender) external;

    function pendingReceivers(address _sender) external returns (address);

    function weth() external view returns (address);

    function gmx() external view returns (address);

    function bnGmx() external view returns (address);

    function esGmx() external view returns (address);

    function feeGmxTracker() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function stakedGlpTracker() external view returns (address);

    function stakedGmxTracker() external view returns (address);

    function bonusGmxTracker() external view returns (address);

    function glpManager() external view returns (address);
}

// SPDX-License-Identifier: MIT

// https://arbiscan.io/address/0x2F546AD4eDD93B956C8999Be404cdCAFde3E89AE#code
pragma solidity 0.8.17;

interface IStakedGlp {
    function approve(address _spender, uint256 _amount) external returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRewardDistributor {
    function pendingRewards() external view returns (uint256);

    function setTokensPerInterval(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IPirexRewards {
    function accrueStrategy()
        external
        returns (
            ERC20[] memory _producerTokens,
            ERC20[] memory rewardTokens,
            uint256[] memory rewardAmounts
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import {IVault} from "src/interfaces/IVault.sol";

interface IGlpManager {
    function vault() external view returns (IVault);

    function usdg() external view returns (address);

    function MAX_COOLDOWN_DURATION() external view returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function cooldownDuration() external returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import {IVault} from "src/interfaces/IVault.sol";

interface IVault {
    function whitelistedTokens(address _token) external view returns (bool);

    function priceFeed() external view returns (address);

    function poolAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount)
        external
        view
        returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IRewardRouterV2} from "src/interfaces/IRewardRouterV2.sol";
import {IStakedGlp} from "src/interfaces/IStakedGlp.sol";
import {IPirexGmx} from "src/interfaces/IPirexGmx.sol";

contract PirexGmxCooldownHandler {
    using SafeTransferLib for ERC20;

    IPirexGmx public immutable pirexGmx;

    error MustBePirexGmx();

    constructor() {
        pirexGmx = IPirexGmx(msg.sender);
    }

    /**
        @notice Mint + stake GLP and deposit them into PirexGmx on behalf of a user
        @param  rewardRouter   IRewardRouterV2  GLP Reward Router interface instance
        @param  stakedGlp      IStakedGlp       StakedGlp interface instance
        @param  glpManager     address          GlpManager contract address
        @param  token          address          GMX-whitelisted token for minting GLP
        @param  tokenAmount    uint256          Whitelisted token amount
        @param  minUsdg        uint256          Minimum USDG purchased and used to mint GLP
        @param  minGlp         uint256          Minimum GLP amount minted from ERC20 tokens
        @param  receiver       address          pxGLP receiver
        @return deposited      uint256          GLP deposited
        @return postFeeAmount  uint256          pxGLP minted for the receiver
        @return feeAmount      uint256          pxGLP distributed as fees
     */
    function depositGlp(
        IRewardRouterV2 rewardRouter,
        IStakedGlp stakedGlp,
        address glpManager,
        address token,
        uint256 tokenAmount,
        uint256 minUsdg,
        uint256 minGlp,
        address receiver
    )
        external
        payable
        returns (
            uint256 deposited,
            uint256 postFeeAmount,
            uint256 feeAmount
        )
    {
        if (msg.sender != address(pirexGmx)) revert MustBePirexGmx();

        ERC20(token).safeApprove(glpManager, tokenAmount);

        deposited = token == address(0)
            ? rewardRouter.mintAndStakeGlpETH{value: msg.value}(minUsdg, minGlp)
            : rewardRouter.mintAndStakeGlp(token, tokenAmount, minUsdg, minGlp);

        // Handling stakedGLP approvals for each call in case its updated on PirexGmx
        stakedGlp.approve(address(pirexGmx), deposited);

        (postFeeAmount, feeAmount) = pirexGmx.depositFsGlp(deposited, receiver);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {PxERC20} from "src/PxERC20.sol";

interface IPirexGmx {
    enum Fees {
        Deposit,
        Redemption,
        Reward
    }

    function depositFsGlp(uint256 amount, address receiver)
        external
        returns (uint256, uint256);

    function depositGmx(uint256 amount, address receiver)
        external
        returns (uint256, uint256);

    function claimRewards()
        external
        returns (
            ERC20[] memory producerTokens,
            ERC20[] memory rewardTokens,
            uint256[] memory rewardAmounts
        );

    function claimUserReward(
        address rewardTokenAddress,
        uint256 rewardAmount,
        address recipient
    ) external returns (uint256 postFeeAmount, uint256 feeAmount);

    function fees(Fees fee) external view returns (uint256);

    function pxGmx() external view returns (PxERC20);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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