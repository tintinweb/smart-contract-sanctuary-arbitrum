pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import {ILendingPool} from "IAaveLendingPoolV2.sol";
import "ISwapRouter.sol";
import "ERC20.sol"; 
import "Ownable.sol"; 

interface RewardRouterV2 {
  function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
  function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
  function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
}

interface RewardTracker {
  function claimable(address _account) external view returns (uint256);
}

interface GlpManager {
  function getAumInUsdg(bool maximise) external view returns (uint256);
}

interface AggregatorV3Interface {
  function latestRoundData() external view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 amount) external;
}

/**
 * Delta Neutral GLP farming strategy
 
    Balance: for $100 of GLP, delta neutral user should be short the other tokens
      Current pool composition:
        - Total $390M
        - USDC+USDT+DAI+FRAX 198 = 50%
        - ETH: $115M ~30%
        - BTC $70M  ~18%
        - LINK 4.5M, UNI 3M   LINK+UNI ~2%
        
    - Cannot perfectly hedge but try to maintain 34% ETH 16%  BTC hedge
    - borrow assets on Aave:
      - deposit USDC
      - borrow ETH
      - swap ETH for GLP
      
      - General function: for source X% in pool, need to hedge X-100 by borrowing in Aave with 66% LTV
      - For Usd, shareAsset = 50%, put 40% directly, 60% in Aave to borrow 40% of assets to hedge: efficiency 80%
      - For Eth, shareAsset = 1/3, put 25% directly, 75% in Aave to borrow 50% of assets to hedge: efficiency 75%
      - For Btc, shareAsset = 1/6, put 13.8% directly, 86.2% in Aave to borrow 57.5% of assets: efficiency 71%
        
 */
contract KamehaGlpEth is ERC20, Ownable {

  /// CONSTANTS
  RewardRouterV2 constant GMX_REWARD_ROUTER = RewardRouterV2(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1);
  RewardTracker constant GMX_REWARD_TRACKER = RewardTracker(0x4e971a87900b931fF39d1Aad67697F49835400b6);
  address constant GMX_GLP_MANAGER = 0x321F653eED006AD1C29D174e17d96351BDe22649;
  ERC20 constant STAKED_GLP_TRACKER = ERC20(0x1aDDD80E6039594eE970E5872D247bf0414C8903);
  
  AggregatorV3Interface constant ETH_ORACLE = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
  AggregatorV3Interface constant USDC_ORACLE = AggregatorV3Interface(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
  AggregatorV3Interface constant WBTC_ORACLE = AggregatorV3Interface(0x6ce185860a4963106506C203335A2910413708e9);
  
  
  ILendingPool constant AAVE_LP = ILendingPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
  ISwapRouter constant SWAP_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
  address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  
  address constant VARDEBT_WETH = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;
  address constant VARDEBT_WBTC = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;
  address constant VARDEBT_USDC = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  /// VARS
  uint public lifetimeRewardsETH;
  bool public isPaused = false;
  uint public rewardThreshold = 1e16;
  
  address public treasury = 0xC0D7223db9850C87268c178E8b46cea10DbA90E1;
  uint8 public treasuryFee = 5; // fee in percent
  
  /// EVENTS
  event Deposit(address user, uint amount, uint shares);
  event Withdraw(address user, uint amount, uint shares);
  

  constructor() ERC20("Kameha GLP-E", "KGE") {
    ERC20(USDC).approve(address(GMX_GLP_MANAGER), 2**256-1);
    ERC20(WETH).approve(address(GMX_GLP_MANAGER), 2**256-1);
    ERC20(WBTC).approve(address(GMX_GLP_MANAGER), 2**256-1);
    ERC20(USDC).approve(address(AAVE_LP), 2**256-1);
    ERC20(WETH).approve(address(AAVE_LP), 2**256-1);
    ERC20(WBTC).approve(address(AAVE_LP), 2**256-1);
    ERC20(USDC).approve(address(SWAP_ROUTER), 2**256-1);
  }
  receive() external payable {}
  
  /// @notice Pause/unpause deposits: prevents griefing attack where dust deposit every 15mn prevents withdrawals for 15mn
  function allowDeposits(bool isPaused_) public onlyOwner {
    isPaused = isPaused_;
  }
  /// @notice Change the threshold for claiming+compounding rewards
  function changeRewardThreshold (uint limit) public onlyOwner {
    rewardThreshold = limit;
  }
  
  ///@notice Change treasury address
  function updateTreasury (address treasury_, uint8 treasuryFee_) public onlyOwner {
    treasury = treasury_;
    treasuryFee = treasuryFee_;
  }

  
  /// @notice User deposits WETH and opens a delta neutral GLP position
  function depositETH() public payable {
    require(msg.value > 0, "Invalid msg.value");
    IWETH(WETH).deposit{value: msg.value}();
    harvestAndCompound();
    _mintDeltaNeutralGLP(msg.value, true);
  }  


  /// @notice User deposits WETH and opens a delta neutral GLP position
  function deposit(uint amount) public {
    require (amount > 0, "Invalid Amount");
    harvestAndCompound();
    ERC20(WETH).transferFrom(msg.sender, address(this), amount);
    _mintDeltaNeutralGLP(amount, true);
  }  


    
  /// @notice Use a bunch of USDC to create a delta neutral position.
  /// @param amount Amount of WETH
  /// @param mintTokens True if kamGlp tokens are minted (user depositing USDC), False if compounding rewards
  function _mintDeltaNeutralGLP (uint amount, bool mintTokens) private {
    require(isPaused == false, "Deposits paused");
    
    uint glpBalance = STAKED_GLP_TRACKER.balanceOf(address(this));
    
    // 1. mint GLP with 25% ETH
    uint glpAmount = GMX_REWARD_ROUTER.mintAndStakeGlp(WETH, amount * 25 / 100, 0, 1);

    // 2. deposit remaing 75% in Aave
    AAVE_LP.deposit(WETH, amount * 75 / 100, address(this), 0);
    
    // 2. borrow amount*50% worth of USDC+WBTC (Aave LTV 80%, 50/75 ~ 66%), USDC:BTC ratio ~ 3:1, USDC=37.5% BTC =12.5%
    // btcAmount * btcPrice / btcDecimals = amount * usdcPrice / usdcDecimals
    uint usdcAmount = (amount * 375 / 1000) * latestEthPrice() / 10**12 / latestUsdcPrice(); // USDC 6 to WETH 18 decimals
    uint wbtcAmount = (amount * 125 / 1000) * latestEthPrice() / 10**10  / latestWbtcPrice();  // WBTC 8 to WETH 18 decimals

    AAVE_LP.borrow(USDC, usdcAmount, 2, 0, address(this));
    AAVE_LP.borrow(WBTC, wbtcAmount, 2, 0, address(this));

    // 3. mint GLP with ETH then with BTC
    glpAmount += GMX_REWARD_ROUTER.mintAndStakeGlp(USDC, usdcAmount, 0, 1);
    glpAmount += GMX_REWARD_ROUTER.mintAndStakeGlp(WBTC, wbtcAmount, 0, 1);
    
    // 4. Mint local token based on GLP minted
    if (mintTokens) {
      uint mintAmount;
      if (glpBalance == 0) mintAmount = glpAmount;
      else mintAmount = totalSupply() * glpAmount / glpBalance;
      _mint(msg.sender, mintAmount);
      emit Deposit(msg.sender, amount, mintAmount);
    }
  }
  
  /// @notice Withdraw from GLP pool as WETH
  function withdraw(uint shares) public {
    uint amountOut = _withdraw(shares);
    ERC20(WETH).transfer(msg.sender, amountOut );
  }
  
  /// @notice Withdraw from GLP pool and unwrap to ETH
  function withdrawETH(uint shares) public {
    uint amountOut = _withdraw(shares);
    IWETH(WETH).withdraw(amountOut);
    payable(msg.sender).transfer(amountOut);
  }
  
  /// @notice User redeems some tokens for USDC
  /// @dev Those tokens are burned, and the equivalent underlying GLP amount is redeemed for WETH, which is partly used to repay Aave debt
  function _withdraw(uint shares) internal returns (uint amountOut){
    require (shares > 0, "Invalid Amount");
    // 0. Dont compound rewards or will reset cooldown
    //harvestAndCompound();
    uint glpBalance = STAKED_GLP_TRACKER.balanceOf(address(this));
    uint shareSupply = totalSupply();

    // 1. Withdraw as USDC
    uint redeemedUSDC = GMX_REWARD_ROUTER.unstakeAndRedeemGlp(USDC, glpBalance * shares / shareSupply, 1, address(this) );

    // 2. Repay Aave USDC+WBTC debt in proportion
    uint debt = ERC20(VARDEBT_USDC).balanceOf(address(this));
    AAVE_LP.repay(USDC, debt * shares / shareSupply, 2, address(this));

    // wBTC debt
    debt = ERC20(VARDEBT_WBTC).balanceOf(address(this)) * shares / shareSupply;
    _swapUsdcForExactWbtc(debt);
    AAVE_LP.repay(WBTC, debt, 2, address(this));

    // 3. Withdraw Aave WETH in proportion
    uint wethAave = ERC20(0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8).balanceOf(address(this)); // aWETH 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8
    AAVE_LP.withdraw(WETH, wethAave * shares / shareSupply, address(this));
    
    // 4. There should be an excess USDC: convert, send all USDC remaining to user
    _swapAllUsdcToWeth();
    amountOut = ERC20(WETH).balanceOf(address(this));
    
    // 5. burn
    _burn(msg.sender, shares);
    emit Withdraw(msg.sender, amountOut, shares);
  }
  
  
  /// @notice Harvest fees from reward router, then convert all WETH to USDC and compound
  function harvestAndCompound() public {
    // if rewards less than 0.01 Eth just return
    if ( GMX_REWARD_TRACKER.claimable(address(this)) < rewardThreshold ) return;
    
    // 1. get rewards from Reward router
    GMX_REWARD_ROUTER.handleRewards(true, false, true, false, true, true, false); //withdraw all, dont stake, get ETH as WETH
    
    // 2. Send fee to treasury
    if (treasuryFee > 0) ERC20(WETH).transfer(treasury, ERC20(WETH).balanceOf(address(this)) * treasuryFee / 100);
    
    // 3. Swap WETH to USDC then compound
    uint amountOut = _swapAllUsdcToWeth();
    if (amountOut > 0){
      lifetimeRewardsETH+= amountOut;
      _mintDeltaNeutralGLP(amountOut, false);
    }
  }
  
  
  /** @notice Rebalance positions
    Adding liquidity to the pool will push back towards the balance, however withdrawing doesn'than
    If the pool HR moves, the GLP is rebalanced and the hedge moves futrher away from the balance
    Worst case when it is too high the Aave position can be liquidated.
    
    In some cases it may be necessary to call for a rebalancing:
      - if HR too high (LTV too low), remove some USDC from Aave and add it to the pool
      - if HR too low (LTV too high), withdraw some GLP and repay some debt, but don't withdraw USDC
      
    Base LTV is 40/60 = 66%, if LTV<62% or LTV>71% allow rebalance
  */
  function rebalance() public returns (uint) {
    (uint collateral, uint debt,,,,) = AAVE_LP.getUserAccountData(address(this));
    // if LTV < 62%, rebalance up
    if (debt * 100 / collateral < 62){
      // simple way not gas efficient: withdraw excess USDC, then add that amount to pool
      uint rebalUsdAmount = collateral - debt * 100 / 66;
      uint rebalWeth = rebalUsdAmount * 1e18 / latestEthPrice();
      AAVE_LP.withdraw(WETH, rebalWeth, address(this));
      _mintDeltaNeutralGLP(rebalWeth, false);
      // TODO: gas efficiency, since adding to pool will deposit back some amount, just borrow the difference
    }
    else if ( debt * 100 / collateral > 71 ){
      // withdraw some GLP and repay debt
      uint rebalUsdAmount = debt - collateral * 71 / 100; // amount of debt to repay in USDX8
      uint rebalGlp = rebalUsdAmount * 10**18 / latestGlpPrice();
      uint redeemedUSDC = GMX_REWARD_ROUTER.unstakeAndRedeemGlp(USDC, rebalGlp, 1, address(this) );
      _swapExactUsdcForWbtc(redeemedUSDC / 4); // swap a quarter to BTC

      AAVE_LP.repay(USDC, ERC20(USDC).balanceOf(address(this)), 2, address(this));
      AAVE_LP.repay(WBTC, ERC20(WBTC).balanceOf(address(this)), 2, address(this));
    }
  }
  
  /// @notice Swap all WETH local balance to USDC
  function _swapAllUsdcToWeth() private returns (uint amountOut){
    uint amountIn = ERC20(USDC).balanceOf(address(this));
    if (amountIn == 0) return 0;
    ISwapRouter.ExactInputSingleParams memory params =
      ISwapRouter.ExactInputSingleParams({
          tokenIn: USDC,
          tokenOut: WETH,
          fee: 500,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: amountIn,
          amountOutMinimum: amountIn * latestUsdcPrice() / latestEthPrice() * 98 / 100, // tolerable slippage 2%
          sqrtPriceLimitX96: 0
      });
    amountOut = SWAP_ROUTER.exactInputSingle(params);
  }
  
  
  /// @notice Swaps USDC for some BTC
  function _swapUsdcForExactWbtc(uint amountOut) internal returns (uint amountIn){
    ISwapRouter.ExactOutputSingleParams memory params =
      ISwapRouter.ExactOutputSingleParams({
          tokenIn: USDC,
          tokenOut: WBTC,
          fee: 500,
          recipient: address(this),
          deadline: block.timestamp,
          amountOut: amountOut,
          amountInMaximum:  amountOut * latestWbtcPrice() / latestUsdcPrice() * 102 / 100, // tolerable slippage 2
          sqrtPriceLimitX96: 0
      });
    amountIn = SWAP_ROUTER.exactOutputSingle(params);
  }
  
  /// @notice Swaps some ETH for BTC
  function _swapExactUsdcForWbtc(uint amountIn) internal returns (uint amountOut){
    ISwapRouter.ExactInputSingleParams memory params =
      ISwapRouter.ExactInputSingleParams({
          tokenIn: USDC,
          tokenOut: WBTC,
          fee: 3000,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: amountIn,
          amountOutMinimum: amountIn * latestUsdcPrice() / latestWbtcPrice() * 98 / 100, // tolerable slippage 2%
          sqrtPriceLimitX96: 0
      });
    amountOut = SWAP_ROUTER.exactInputSingle(params);
  }
  
  
  /// @notice withdraw stuck tokens other than GLP: GMX, esGMX, ...
  /*function emptyToken (address token) onlyOwner public {
    ERC20(token).transfer( msg.sender, ERC20(token).balanceOf(address(this))  );
  }*/
  
  function latestEthPrice() public view returns (uint priceX8){
    (, int256 price,,,) = ETH_ORACLE.latestRoundData();
    priceX8 = uint(price);
  }
  function latestUsdcPrice() public view returns (uint priceX8){
    (, int256 price,,,) = USDC_ORACLE.latestRoundData();
    priceX8 = uint(price);
  }
  function latestWbtcPrice() public view returns (uint priceX8){
    (, int256 price,,,) = WBTC_ORACLE.latestRoundData();
    priceX8 = uint(price);
  }
  function latestGlpPrice() public view returns (uint priceX8){
    uint aumInUsdg = GlpManager(GMX_GLP_MANAGER).getAumInUsdg(true);
    uint glpBalance = ERC20(STAKED_GLP_TRACKER).totalSupply();
    priceX8 = aumInUsdg * 10**8 / glpBalance;
  }
  function latestPrice() public view returns (uint priceX8){
    uint glpBalance = STAKED_GLP_TRACKER.balanceOf(address(this));
    priceX8 = glpBalance * latestGlpPrice() / 10**10;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "ILendingPoolAddressesProvider.sol";
import {DataTypes} from "DataTypes.sol";

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
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

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
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

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
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

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

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

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
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
  
  function PMTransfer(
    address collateralAsset,
    address user,
    uint256 amount
  ) external;
  
  function PMTransferTo(
    address collateralAsset,
    address user,
    uint256 amount
  ) external;
  
  function PMAssign(
    address _pm
  ) external;
  
  function PMWithdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
  
  function PMSet(
    address _pm,
    bool _state
  ) external;
  
  function setSoftLiquidationThreshold(
    uint256 _threshold
  ) external;
  
  function pm() external view returns (address);
  function LENDINGPOOL_REVISION() external view returns (uint);
  function disableReserveAsCollateral(address, address) external;


}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

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

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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