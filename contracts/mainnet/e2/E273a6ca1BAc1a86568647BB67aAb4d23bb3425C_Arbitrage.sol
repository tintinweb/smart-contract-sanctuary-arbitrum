// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './CollateralPool.sol';
import './Interfaces/IXSDWETHpool.sol';
import './Interfaces/IBankXWETHpool.sol';
import '../XSDStablecoin.sol';
import '../../UniswapFork/Interfaces/IRouter.sol';
import "./CollateralPoolLibrary.sol";
import '../../Oracle/Interfaces/IPIDController.sol';
import "../../BankX/BankXToken.sol";

contract Arbitrage is ReentrancyGuard{
    address public xsd_address;
    address public bankx_address;
    address public smartcontract_owner;
    address public router_address;
    address public pid_address;
    address public collateral_pool;
    address public xsd_pool;
    address public bankx_pool;
    address public origin_address;

    uint public arbitrage_paused;
    uint public last_update;
    uint public block_delay;
    bool public pause_arbitrage;

    XSDStablecoin private XSD;
    BankXToken private BankX;
    IPIDController private pid_controller;
    IRouter private Router;

constructor(
        address _xsd_address,
        address _bankx_address,
        address _collateral_pool,
        address _router_address,
        address _pid_controller,
        address _xsd_pool,
        address _bankx_pool,
        address _origin_address,
        address _smartcontract_owner,
        uint _block_delay
    ) {
        require((_smartcontract_owner != address(0))
            && (_origin_address != address(0))
            && (_collateral_pool != address(0))
            && (_xsd_pool != address(0))
            && (_bankx_pool != address(0))
            && (_router_address != address(0))
            && (_xsd_address != address(0))
            && (_bankx_address != address(0))
            && (_pid_controller != address(0))
            , "Zero address detected");
        xsd_address = _xsd_address;
        XSD = XSDStablecoin(_xsd_address);
        bankx_address = _bankx_address;
        BankX = BankXToken(_bankx_address);
        collateral_pool = _collateral_pool;
        router_address = _router_address;
        Router = IRouter(_router_address);
        pid_address = _pid_controller;
        pid_controller = IPIDController(_pid_controller);
        smartcontract_owner = _smartcontract_owner;
        origin_address = _origin_address;
        bankx_pool = _bankx_pool;
        xsd_pool = _xsd_pool;
        block_delay = _block_delay;
    }

function burnBankX(uint256 bankx_amount,uint256 eth_min_amount, uint256 bankx_min_amount, uint256 deadline) external nonReentrant {
    require(pause_arbitrage, "Arbitrage Paused");
    require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
    uint256 time_elapsed = block.timestamp - last_update;
    require(time_elapsed >= arbitrage_paused, "internal cooldown not passed");
    uint256 bankx_price = pid_controller.bankx_updated_price();
    uint256 xag_usd_price = XSD.xag_usd_price();
    uint silver_price = (xag_usd_price*(1e4))/(311035);
    require(pid_controller.xsd_updated_price()>(silver_price + (silver_price/1e3)), "BurnBankX:ARBITRAGE ERROR");
    (uint256 xsd_amount) = CollateralPoolLibrary.calcMintAlgorithmicXSD(
    bankx_price, 
    xag_usd_price,
    bankx_amount
    );
    BankX.pool_burn_from(msg.sender, bankx_amount);
    XSD.pool_mint(msg.sender, xsd_amount);
    Router.swapXSDForBankX(xsd_amount,msg.sender, eth_min_amount, bankx_min_amount,deadline);
    pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
    last_update = block.timestamp;
    pid_controller.systemCalculations();
}

function burnXSD(uint256 XSD_amount,uint256 eth_min_amount, uint256 xsd_min_amount, uint256 deadline) external nonReentrant {
    require(pause_arbitrage, "Arbitrage Paused");
    require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
    uint256 time_elapsed = block.timestamp - last_update;
    require(time_elapsed >= arbitrage_paused, "internal cooldown not passed");
    uint256 xag_usd_price = XSD.xag_usd_price();
    uint silver_price = (xag_usd_price*(1e4))/(311035); 
    require(pid_controller.xsd_updated_price()<(silver_price - (silver_price/1e3)), "BurnXSD:ARBITRAGE ERROR");
    uint256 bankx_dollar_value_d18 = (XSD_amount*xag_usd_price)/(31103477); 
    uint256 bankx_amount = (bankx_dollar_value_d18*(1e6))/pid_controller.bankx_updated_price();
    if(XSD.totalSupply()>CollateralPool(payable(collateral_pool)).collat_XSD()){
        XSD.pool_burn_from(msg.sender,XSD_amount);    }
    else{
        TransferHelper.safeTransferFrom(xsd_address, msg.sender,origin_address, XSD_amount);
    }
    BankX.pool_mint(msg.sender, bankx_amount);
    Router.swapBankXForXSD(bankx_amount,msg.sender, eth_min_amount, xsd_min_amount,deadline);
    pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
    last_update = block.timestamp;
    pid_controller.systemCalculations();
}
function setArbitrageCooldown(uint sec) external {
    require(msg.sender == smartcontract_owner, "Only the owner can access this function");
    arbitrage_paused = block.timestamp + sec;
}
function pauseArbitrage() external {
    require(msg.sender == smartcontract_owner, "Only the owner can access this function");
    pause_arbitrage = !pause_arbitrage;
}
function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(_smartcontract_owner != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

function renounceOwnership() external{
    require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
    smartcontract_owner = address(0);
}

function resetAddresses(address _xsd_address,
        address _bankx_address,
        address _collateral_pool,
        address _router_address,
        address _pid_controller,
        address _xsd_pool,
        address _bankx_pool,
        address _origin_address,
        address _smartcontract_owner, 
        uint _block_delay) external{
    require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
    require((_smartcontract_owner != address(0))
            && (_origin_address != address(0))
            && (_collateral_pool != address(0))
            && (_xsd_pool != address(0))
            && (_bankx_pool != address(0))
            && (_router_address != address(0))
            && (_xsd_address != address(0))
            && (_bankx_address != address(0))
            && (_pid_controller != address(0))
            , "Zero address detected");
        xsd_address = _xsd_address;
        XSD = XSDStablecoin(_xsd_address);
        bankx_address = _bankx_address;
        BankX = BankXToken(_bankx_address);
        collateral_pool = _collateral_pool;
        router_address = _router_address;
        Router = IRouter(_router_address);
        pid_address = _pid_controller;
        pid_controller = IPIDController(_pid_controller);
        smartcontract_owner = _smartcontract_owner;
        origin_address = _origin_address;
        bankx_pool = _bankx_pool;
        xsd_pool = _xsd_pool;
        block_delay = _block_delay;
}
}

// SPDX-License-Identifier: MIT
/*
BBBBBBBBBBBBBBBBB                                         kkkkkkkk         XXXXXXX       XXXXXXX
B::::::::::::::::B                                        k::::::k         X:::::X       X:::::X
B::::::BBBBBB:::::B                                       k::::::k         X:::::X       X:::::X
BB:::::B     B:::::B                                      k::::::k         X::::::X     X::::::X
  B::::B     B:::::B   aaaaaaaaaaaaa   nnnn  nnnnnnnn      k:::::k kkkkkkk XXX:::::X   X:::::XXX
  B::::B     B:::::B   a::::::::::::a  n:::nn::::::::nn    k:::::k k:::::k    X:::::X X:::::X
  B::::BBBBBB:::::B    aaaaaaaaa:::::a n::::::::::::::nn   k:::::k k:::::k     X:::::X:::::X
  B:::::::::::::BB              a::::a nn:::::::::::::::n  k:::::k k:::::k      X:::::::::X
  B::::BBBBBB:::::B      aaaaaaa:::::a   n:::::nnnn:::::n  k::::::k:::::k       X:::::::::X
  B::::B     B:::::B   aa::::::::::::a   n::::n    n::::n  k:::::::::::k       X:::::X:::::X
  B::::B     B:::::B  a::::aaaa::::::a   n::::n    n::::n  k:::::::::::k      X:::::X X:::::X
  B::::B     B:::::B a::::a    a:::::a   n::::n    n::::n  k::::::k:::::k  XXX:::::X   X:::::XXX
BB:::::BBBBBB::::::B a::::a    a:::::a   n::::n    n::::n k::::::k k:::::k X::::::X     X::::::X
B:::::::::::::::::B  a:::::aaaa::::::a   n::::n    n::::n k::::::k k:::::k X:::::X       X:::::X
B::::::::::::::::B    a::::::::::aa:::a  n::::n    n::::n k::::::k k:::::k X:::::X       X:::::X
BBBBBBBBBBBBBBBBB      aaaaaaaaaa  aaaa  nnnnnn    nnnnnn kkkkkkkk kkkkkkk XXXXXXX       XXXXXXX


                                          Currency Creators Manifesto

Our world faces an urgent crisis of currency manipulation, theft and inflation.  Under the current system, currency is controlled by and benefits elite families, governments and large banking institutions.  We believe currencies should be minted by and benefit the individual, not the establishment.  It is time to take back the control of and the freedom that money can provide.

BankX is rebuilding the legacy banking system from the ground up by providing you with the capability to create currency and be in complete control of wealth creation with a concept we call ‘Individual Created Digital Currency’ (ICDC). You own the collateral.  You mint currency.  You earn interest.  You leverage without the risk of liquidation.  You stake to earn even more returns.  All of this is done with complete autonomy and decentralization.  BankX has built a stablecoin for Individual Freedom.

BankX is the antidote for the malevolent financial system bringing in a new future of freedom where you are in complete control with no middlemen, bank or central bank between you and your finances. This capability to create currency and be in complete control of wealth creation will be in the hands of every individual that uses BankX.

By 2030, we will rid the world of the corrupt, tyrannical and incompetent banking system replacing it with a system where billions of people will be in complete control of their financial future.  Everyone will be given ultimate freedom to use their assets to create currency, earn interest and multiply returns to accomplish their individual goals.  The mission of BankX is to be the first to mint $1 trillion in stablecoin. 

We will bring about this transformation by attracting people that believe what we believe.  We will partner with other blockchain protocols and build decentralized applications that drive even more usage.  Finally, we will deploy a private network that is never connected to the Internet to communicate between counterparties, that allows for blockchain-to-blockchain interoperability and stores private keys and cryptocurrency wallets.  Our ecosystem, network and platform has never been seen in the market and provides us with a long term sustainable competitive advantage.

We value individual freedom.
We believe in financial autonomy.
We are anti-establishment.
We envision a future of self-empowerment.

*/
pragma solidity ^0.8.0;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "../../BankX/BankXToken.sol";
import "../XSDStablecoin.sol";
import "./Interfaces/IBankXWETHpool.sol";
import "./Interfaces/IXSDWETHpool.sol";
import '../../Oracle/Interfaces/IPIDController.sol';
import "../../ERC20/IWETH.sol";
import "./CollateralPoolLibrary.sol";

contract CollateralPool is ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */

    address public WETH;
    address public smartcontract_owner;
    address public xsd_contract_address;
    address public bankx_contract_address;
    address public xsdweth_pool;
    address public bankxweth_pool;
    address public pid_address;
    BankXToken private BankX;
    XSDStablecoin private XSD;
    IPIDController private pid_controller;
    uint256 public collat_XSD;
    bool public mint_paused;
    bool public redeem_paused;
    bool public buyback_paused;
    struct MintInfo {
        uint256 accum_interest; //accumulated interest from previous mints
        uint256 interest_rate; //interest rate at that particular timestamp
        uint256 time; //last timestamp
        uint256 amount; //XSD amount minted
    }
    mapping(address=>MintInfo) public mintMapping; 
    mapping (address => uint256) public redeemBankXBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    mapping (address => uint256) public vestingtimestamp;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolBankX;
    uint256 public collateral_equivalent_d18;
    uint256 public bankx_minted_count;
    mapping (address => uint256) public lastRedeemed;
    uint256 public block_delay = 2;
    /* ========== MODIFIERS ========== */
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BankXRouter: EXPIRED');
        _;
    }

    modifier onlyByOwner() {
        require(msg.sender == smartcontract_owner, "Not owner");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _xsd_contract_address,
        address _bankx_contract_address,
        address _bankxweth_pool,
        address _xsdweth_pool,
        address _WETH,
        address _smartcontract_owner
    ) {
        require(
            (_xsd_contract_address != address(0))
            && (_bankx_contract_address != address(0))
            && (_WETH != address(0))
            && (_bankxweth_pool != address(0))
            && (_xsdweth_pool != address(0))
        , "Zero address detected"); 
        XSD = XSDStablecoin(_xsd_contract_address);
        BankX = BankXToken(_bankx_contract_address);
        xsd_contract_address = _xsd_contract_address;
        bankx_contract_address = _bankx_contract_address;
        xsdweth_pool = _xsdweth_pool;
        bankxweth_pool = _bankxweth_pool;
        WETH = _WETH;
        smartcontract_owner = _smartcontract_owner;
    }

    /* ========== VIEWS ========== */

    //only accept ETH via fallback function from the WETH contract
    receive() external payable {
        assert(msg.sender == WETH);
    }

    // Returns dollar value of collateral held in this XSD pool
    function collatDollarBalance() public view returns (uint256) {
            return ((IWETH(WETH).balanceOf(address(this))*XSD.eth_usd_price())/(1e6));        
    }

    // Returns the value of excess collateral held in this XSD pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 global_collateral_ratio = XSD.global_collateral_ratio();
        uint256 global_collat_value = XSD.globalCollateralValue();

        if (global_collateral_ratio > (1e6)) global_collateral_ratio = (1e6); // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = ((collat_XSD)*global_collateral_ratio*(XSD.xag_usd_price()*(1e4))/(311035))/(1e12); // Calculates collateral needed to back each 1 XSD with $1 of collateral at current collat ratio
        if ((global_collat_value-unclaimedPoolCollateral)>required_collat_dollar_value_d18) return (global_collat_value-unclaimedPoolCollateral-required_collat_dollar_value_d18);
        else return 0;
    }
    /* ========== INTERNAL FUNCTIONS ======== */
    //call the price check function again after check.

    function mintInterestCalc(uint xsd_amount,address sender) internal {
        (mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount) = CollateralPoolLibrary.calcMintInterest(xsd_amount,XSD.xag_usd_price(), XSD.interest_rate(), mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount);
    }
    function redeemInterestCalc(uint xsd_amount,address sender) internal {
        (mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount)=CollateralPoolLibrary.calcRedemptionInterest(xsd_amount,XSD.xag_usd_price(), mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount);
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1XSD(uint256 XSD_out_min, uint256 deadline) external ensure(deadline) payable nonReentrant {
        require(!mint_paused, "Mint Paused");
        require(msg.value>0, "Invalid collateral amount");
        require(XSD.global_collateral_ratio() >= (1e6), "Collateral ratio must be >= 1");
        (uint256 xsd_amount_d18) = CollateralPoolLibrary.calcMint1t1XSD(
            XSD.eth_usd_price(),
            XSD.xag_usd_price(),
            msg.value
        ); //1 XSD for each $1 worth of collateral
        require(XSD_out_min <= xsd_amount_d18, "Slippage limit reached");
        mintInterestCalc(xsd_amount_d18,msg.sender);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(address(this), msg.value));
        collat_XSD = collat_XSD + xsd_amount_d18;
        XSD.pool_mint(msg.sender, xsd_amount_d18);
    }

    // 0% collateral-backed
    function mintAlgorithmicXSD(uint256 bankx_amount_d18, uint256 XSD_out_min, uint256 deadline) external ensure(deadline) nonReentrant {
        require(!mint_paused, "Mint Paused");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before minting");
        uint256 xag_usd_price = XSD.xag_usd_price();
        require(XSD.global_collateral_ratio() == 0, "Collateral ratio must be 0");
        (uint256 xsd_amount_d18) = CollateralPoolLibrary.calcMintAlgorithmicXSD(
            pid_controller.bankx_updated_price(), 
            xag_usd_price,
            bankx_amount_d18
        );
        require(XSD_out_min <= xsd_amount_d18, "Slippage limit reached");
        mintInterestCalc(xsd_amount_d18,msg.sender);
        collat_XSD = collat_XSD + xsd_amount_d18;
        bankx_minted_count = bankx_minted_count + bankx_amount_d18;
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
        BankX.pool_burn_from(msg.sender, bankx_amount_d18);
        XSD.pool_mint(msg.sender, xsd_amount_d18);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalXSD(uint256 bankx_amount, uint256 XSD_out_min, uint256 deadline) external ensure(deadline) payable nonReentrant {
        require(!mint_paused, "Mint Paused");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before minting");
        uint256 xag_usd_price = XSD.xag_usd_price();
        uint256 global_collateral_ratio = XSD.global_collateral_ratio();

        require(global_collateral_ratio < (1e6) && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        CollateralPoolLibrary.MintFF_Params memory input_params = CollateralPoolLibrary.MintFF_Params(
            pid_controller.bankx_updated_price(), //XSD.bankx_price
            XSD.eth_usd_price(),
            bankx_amount,
            msg.value,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 bankx_needed) = CollateralPoolLibrary.calcMintFractionalXSD(input_params);
        mint_amount = (mint_amount*31103477)/((xag_usd_price)); //grams of silver in calculated mint amount
        require(XSD_out_min <= mint_amount, "Slippage limit reached");
        require(bankx_needed <= bankx_amount, "Not enough BankX inputted");
        mintInterestCalc(mint_amount,msg.sender);
        bankx_minted_count = bankx_minted_count + bankx_needed;
        BankX.pool_burn_from(msg.sender, bankx_needed);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(address(this), msg.value));
        collat_XSD = collat_XSD + mint_amount;
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
        XSD.pool_mint(msg.sender, mint_amount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1XSD(uint256 XSD_amount, uint256 COLLATERAL_out_min, uint256 deadline) external ensure(deadline) nonReentrant {
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(!redeem_paused, "Redeem Paused");
        require(XSD.global_collateral_ratio() == (1e6), "Collateral ratio must be == 1");
        require(XSD_amount<=mintMapping[msg.sender].amount, "OVERREDEMPTION ERROR");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before redeeming");
        // convert xsd to $ and then to collateral value
        (uint256 XSD_dollar,uint256 collateral_needed) = CollateralPoolLibrary.calcRedeem1t1XSD(
            XSD.eth_usd_price(),
            XSD.xag_usd_price(),
            XSD_amount
        );
        uint total_xsd_amount = mintMapping[msg.sender].amount;
        require(collateral_needed <= (IWETH(WETH).balanceOf(address(this))-unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        redeemInterestCalc(XSD_amount, msg.sender);
        uint current_accum_interest = (XSD_amount*mintMapping[msg.sender].accum_interest)/total_xsd_amount;
        redeemBankXBalances[msg.sender] = (redeemBankXBalances[msg.sender]+current_accum_interest);
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender]+XSD_dollar;
        unclaimedPoolCollateral = unclaimedPoolCollateral+XSD_dollar;
        lastRedeemed[msg.sender] = block.number;
        unclaimedPoolBankX = (unclaimedPoolBankX+current_accum_interest);
        uint256 bankx_amount = (current_accum_interest*1e6)/pid_controller.bankx_updated_price();
        collat_XSD -= XSD_amount;
        mintMapping[msg.sender].accum_interest = (mintMapping[msg.sender].accum_interest - current_accum_interest);
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
        XSD.pool_burn_from(msg.sender, XSD_amount);
        BankX.pool_mint(address(this), bankx_amount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem XSD for collateral and BankX. > 0% and < 100% collateral-backed
    function redeemFractionalXSD(uint256 XSD_amount, uint256 BankX_out_min, uint256 COLLATERAL_out_min, uint256 deadline) external ensure(deadline) nonReentrant {
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before redeeming");
        require(!redeem_paused, "Redeem Paused");
        require(XSD_amount<=mintMapping[msg.sender].amount, "OVERREDEMPTION ERROR");
        uint256 xag_usd_price = XSD.xag_usd_price();
        uint256 global_collateral_ratio = XSD.global_collateral_ratio();

        require(global_collateral_ratio < (1e6) && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        

        uint256 bankx_dollar_value_d18 = XSD_amount - ((XSD_amount*global_collateral_ratio)/(1e6));
        bankx_dollar_value_d18 = (bankx_dollar_value_d18*xag_usd_price)/(31103477);
        uint256 bankx_amount = (bankx_dollar_value_d18*1e6)/pid_controller.bankx_updated_price();


        uint256 collateral_dollar_value = (XSD_amount*global_collateral_ratio)/(1e6);
        collateral_dollar_value = (collateral_dollar_value*xag_usd_price)/31103477;
        uint256 collateral_amount = (collateral_dollar_value*1e6)/XSD.eth_usd_price();


        require(collateral_amount <= (IWETH(WETH).balanceOf(address(this))-unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(BankX_out_min <= bankx_amount, "Slippage limit reached [BankX]");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender]+collateral_dollar_value;
        unclaimedPoolCollateral = unclaimedPoolCollateral+collateral_dollar_value;
        lastRedeemed[msg.sender] = block.number;
        uint total_xsd_amount = mintMapping[msg.sender].amount;
        redeemInterestCalc(XSD_amount, msg.sender);
        uint current_accum_interest = (XSD_amount*mintMapping[msg.sender].accum_interest)/total_xsd_amount;
        redeemBankXBalances[msg.sender] = redeemBankXBalances[msg.sender]+current_accum_interest;
        bankx_amount = bankx_amount + ((current_accum_interest*1e6)/pid_controller.bankx_updated_price());
        mintMapping[msg.sender].accum_interest = mintMapping[msg.sender].accum_interest - current_accum_interest;
        redeemBankXBalances[msg.sender] = redeemBankXBalances[msg.sender]+bankx_dollar_value_d18;
        unclaimedPoolBankX = unclaimedPoolBankX+bankx_dollar_value_d18+current_accum_interest;
        collat_XSD -= XSD_amount;
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
    
        XSD.pool_burn_from(msg.sender, XSD_amount);
        BankX.pool_mint(address(this), bankx_amount);
    }

    // Redeem XSD for BankX. 0% collateral-backed
    function redeemAlgorithmicXSD(uint256 XSD_amount, uint256 BankX_out_min, uint256 deadline) external ensure(deadline) nonReentrant {
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(!redeem_paused, "Redeem Paused");
        require(XSD_amount<=mintMapping[msg.sender].amount, "OVERREDEMPTION ERROR");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before redeeming");
        require(XSD.global_collateral_ratio() == 0, "Collateral ratio must be 0"); 
        uint256 bankx_dollar_value_d18 = (XSD_amount*XSD.xag_usd_price())/(31103477);

        uint256 bankx_amount = (bankx_dollar_value_d18*1e6)/pid_controller.bankx_updated_price();
        
        lastRedeemed[msg.sender] = block.number;
        uint total_xsd_amount = mintMapping[msg.sender].amount;
        require(BankX_out_min <= bankx_amount, "Slippage limit reached");
        redeemInterestCalc(XSD_amount, msg.sender);
        uint current_accum_interest = XSD_amount*mintMapping[msg.sender].accum_interest/total_xsd_amount; //precision of 6
        redeemBankXBalances[msg.sender] = (redeemBankXBalances[msg.sender]+current_accum_interest);
        bankx_amount = bankx_amount + ((current_accum_interest*1e6)/pid_controller.bankx_updated_price());
        mintMapping[msg.sender].accum_interest = (mintMapping[msg.sender].accum_interest - current_accum_interest);
        redeemBankXBalances[msg.sender] = redeemBankXBalances[msg.sender]+bankx_dollar_value_d18;
        unclaimedPoolBankX = unclaimedPoolBankX+bankx_dollar_value_d18+current_accum_interest;
        collat_XSD -= XSD_amount;
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
        XSD.pool_burn_from(msg.sender, XSD_amount);
        BankX.pool_mint(address(this), bankx_amount);
    }

    // After a redemption happens, transfer the newly minted BankX and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out XSD/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external nonReentrant{
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(!redeem_paused, "Redeem Paused");
        require(((lastRedeemed[msg.sender]+(block_delay)) <= block.number) && ((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before redeeming");
        uint BankXDollarAmount;
        uint CollateralDollarAmount;
        uint BankXAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemBankXBalances[msg.sender] > 0){
            BankXDollarAmount = redeemBankXBalances[msg.sender];
            BankXAmount = (BankXDollarAmount*1e6)/pid_controller.bankx_updated_price();
            redeemBankXBalances[msg.sender] = 0;
            unclaimedPoolBankX = unclaimedPoolBankX-BankXDollarAmount;
            TransferHelper.safeTransfer(address(BankX), msg.sender, BankXAmount);
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralDollarAmount = redeemCollateralBalances[msg.sender];
            CollateralAmount = (CollateralDollarAmount*1e6)/XSD.eth_usd_price();
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral-CollateralDollarAmount;
            IWETH(WETH).withdraw(CollateralAmount); //try to unwrap eth in the redeem
            TransferHelper.safeTransferETH(msg.sender, CollateralAmount);
        }
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
    }

    // Function can be called by an BankX holder to have the protocol buy back BankX with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    // add XSD as a burn option while uXSD value is positive
    // need two seperate functions: one for bankx and one for XSD
    function buyBackBankX(uint256 BankX_amount,uint256 COLLATERAL_out_min, uint256 deadline) external ensure(deadline){
        require(!buyback_paused, "Buyback Paused");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before buyback");
        CollateralPoolLibrary.BuybackBankX_Params memory input_params = CollateralPoolLibrary.BuybackBankX_Params(
            availableExcessCollatDV(),
            pid_controller.bankx_updated_price(),
            XSD.eth_usd_price(),
            BankX_amount
        );

        (collateral_equivalent_d18) = (CollateralPoolLibrary.calcBuyBackBankX(input_params));

        require(COLLATERAL_out_min <= collateral_equivalent_d18, "Slippage limit reached");
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
        // Give the sender their desired collateral and burn the BankX
        BankX.pool_burn_from(msg.sender, BankX_amount);
        TransferHelper.safeTransfer(address(WETH), address(this), collateral_equivalent_d18);
        IWETH(WETH).withdraw(collateral_equivalent_d18);
        TransferHelper.safeTransferETH(msg.sender, collateral_equivalent_d18);
    }
    //buyback with XSD instead of bankx
    function buyBackXSD(uint256 XSD_amount, uint256 collateral_out_min, uint256 deadline) external ensure(deadline){
        require(!buyback_paused, "Buyback Paused");
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks before buyback");
        if(XSD_amount != 0) require((XSD.totalSupply()+XSD_amount)>collat_XSD, "uXSD MUST BE POSITIVE");

        CollateralPoolLibrary.BuybackXSD_Params memory input_params = CollateralPoolLibrary.BuybackXSD_Params(
            availableExcessCollatDV(),
            pid_controller.xsd_updated_price(),
            XSD.eth_usd_price(),
            XSD_amount
        );

        (collateral_equivalent_d18) = (CollateralPoolLibrary.calcBuyBackXSD(input_params));

        require(collateral_out_min <= collateral_equivalent_d18, "Slippage limit reached");
        pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
        XSD.pool_burn_from(msg.sender, XSD_amount);
        TransferHelper.safeTransfer(address(WETH), address(this), collateral_equivalent_d18);
        IWETH(WETH).withdraw(collateral_equivalent_d18);
        TransferHelper.safeTransferETH(msg.sender, collateral_equivalent_d18);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_block_delay, bool _mint_paused, bool _redeem_paused, bool _buyback_paused) external onlyByOwner {
        block_delay = new_block_delay;
        mint_paused = _mint_paused;
        redeem_paused = _redeem_paused;
        buyback_paused = _buyback_paused;
        emit PoolParametersSet(new_block_delay);
    }

    function setPIDController(address new_pid_address) external onlyByOwner {
        pid_controller = IPIDController(new_pid_address);
        pid_address = new_pid_address;
    }
    function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(_smartcontract_owner != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

    function renounceOwnership() external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        smartcontract_owner = address(0);
    }

    function resetAddresses(address _xsd_contract_address,
        address _bankx_contract_address,
        address _bankxweth_pool,
        address _xsdweth_pool,
        address _WETH) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(
            (_xsd_contract_address != address(0))
            && (_bankx_contract_address != address(0))
            && (_WETH != address(0))
            && (_bankxweth_pool != address(0))
            && (_xsdweth_pool != address(0))
        , "Zero address detected"); 
        XSD = XSDStablecoin(_xsd_contract_address);
        BankX = BankXToken(_bankx_contract_address);
        xsd_contract_address = _xsd_contract_address;
        bankx_contract_address = _bankx_contract_address;
        xsdweth_pool = _xsdweth_pool;
        bankxweth_pool = _bankxweth_pool;
        WETH = _WETH;
    }

    /* ========== EVENTS ========== */

    event PoolParametersSet(uint256 new_block_delay);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXSDWETHpool {
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function collatDollarBalance() external returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to) external;
    function skim(address to) external;
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBankXWETHpool {
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function collatDollarBalance() external returns(uint);
    function swap(uint amount0Out, uint amount1Out, address to) external;
    function skim(address to) external;
    function sync() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ERC20/ERC20Custom.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Pools/CollateralPool.sol";
import "./Pools/Interfaces/IBankXWETHpool.sol";
import "./Pools/Interfaces/IXSDWETHpool.sol";
import "../Oracle/ChainlinkETHUSDPriceConsumer.sol";
import "../Oracle/ChainlinkXAGUSDPriceConsumer.sol";

contract XSDStablecoin is ERC20Custom {

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { XSD, BankX }
    ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    ChainlinkXAGUSDPriceConsumer private xag_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    uint8 private xag_usd_pricer_decimals;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public pid_address;
    address public treasury; 
    address public collateral_pool_address;
    address public router;
    address public eth_usd_oracle_address;
    address public xag_usd_oracle_address;
    address public smartcontract_owner;
    uint256 public interest_rate;
    IBankXWETHpool private bankxEthPool;
    IXSDWETHpool private xsdEthPool;
    uint256 public cap_rate;
    uint256 public genesis_supply; 

    // The addresses in this array are added by the oracle and these contracts are able to mint xsd
    address[] public xsd_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public xsd_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public xsd_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of XSD at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    bool public collateral_ratio_paused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(xsd_pools[msg.sender] == true, "Only xsd pools can call this function");
        _;//check happens before the function is executed 
    } 

    modifier onlyByOwner(){
        require(msg.sender == smartcontract_owner, "You are not the owner");
        _;
    }
    
    modifier onlyByOwnerPID() {
        require(msg.sender == smartcontract_owner || msg.sender == pid_address, "You are not the owner or the pid controller");
        _;
    }

    modifier onlyByOwnerOrPool() {
        require(
            msg.sender == smartcontract_owner  
            || xsd_pools[msg.sender] == true, 
            "You are not the owner or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pool_amount,
        uint256 _genesis_supply,
        address _smartcontract_owner,
        address _treasury,
        uint256 _cap_rate
    ) {
        require((_smartcontract_owner != address(0))
                && (_treasury != address(0)), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        genesis_supply = _genesis_supply + _pool_amount;
        treasury = _treasury;
        _mint(_smartcontract_owner, _pool_amount);
        _mint(treasury, _genesis_supply);
        smartcontract_owner = _smartcontract_owner;
        xsd_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // XSD system starts off fully collateralized (6 decimals of precision)
        interest_rate = 52800; //interest rate starts off at 5%
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 800000; // Change price target to 1 gram of silver
        price_band = 5000; // Collateral ratio will not adjust if 0.005 off target at genesis
        cap_rate = _cap_rate;// Maximum mint amount
    }
    /* ========== VIEWS ========== */

    function pool_price(PriceChoice choice) internal view returns (uint256) {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 _eth_usd_price = (uint256(eth_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth = 0;
        uint256 reserve0;
        uint256 reserve1;

        if (choice == PriceChoice.XSD) {
            (reserve0, reserve1, ) = xsdEthPool.getReserves();
            if(reserve0 == 0 || reserve1 == 0){
                return 1;
            }
            price_vs_eth = reserve0/(reserve1); // How much XSD if you put in 1 WETH
        }
        else if (choice == PriceChoice.BankX) {
            (reserve0, reserve1, ) = bankxEthPool.getReserves();
            if(reserve0 == 0 || reserve1 == 0){
                return 1;
            }
            price_vs_eth = reserve0/(reserve1);  // How much BankX if you put in 1 WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (XSD) or 1 (BankX)");

        // Will be in 1e6 format
        return _eth_usd_price/price_vs_eth;
    }

    
    //XSD price
    function xsd_price() public view returns (uint256) {
        return pool_price(PriceChoice.XSD);
    }

    function bankx_price()  public view returns (uint256) {
        return pool_price(PriceChoice.BankX);
    }

    function eth_usd_price() public view returns (uint256) {
        return (uint256(eth_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** eth_usd_pricer_decimals);
    }
    //silver price
    //hard coded value for testing on goerli
    function xag_usd_price() public view returns (uint256) {
        return (uint256(xag_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** xag_usd_pricer_decimals);
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function xsd_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            pool_price(PriceChoice.XSD), // xsd_price()
            pool_price(PriceChoice.BankX), // bankx_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            (uint256(eth_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // Iterate through all xsd pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 collateral_amount = 0;
        collateral_amount = CollateralPool(payable(collateral_pool_address)).collatDollarBalance();
        return collateral_amount;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    // To simulate global collateral ratio set xsd price higher than silver price and hit refresh collateral ratio.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        uint256 xsd_price_cur = xsd_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setXSDStep()) 
        
        if (xsd_price_cur > (price_target+price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= xsd_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio-xsd_step;
            }
        } else if (xsd_price_cur < price_target-price_band) { //increase collateral ratio
            if(global_collateral_ratio+xsd_step >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio+xsd_step;
            }
        }
        else
        last_call_time = block.timestamp; // Set the time of the last expansion
        uint256 _interest_rate = (1000000-global_collateral_ratio)/(2);
        //update interest rate
        if(_interest_rate>52800){
            interest_rate = _interest_rate;
        }
        else{
            interest_rate = 52800;
        }

        emit CollateralRatioRefreshed(global_collateral_ratio);
    }

    function creatorMint(uint256 amount) public onlyByOwner{
        require(genesis_supply+amount<cap_rate,"cap limit reached");
        super._mint(treasury,amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit XSDBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other xsd pools will call to mint new XSD 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit XSDMinted(msg.sender, m_address, m_amount);
    }
    

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwner {
        require(pool_address != address(0), "Zero address detected");

        require(xsd_pools[pool_address] == false, "Address already exists");
        xsd_pools[pool_address] = true; 
        xsd_pools_array.push(pool_address);

        emit PoolAdded(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwner {
        require(pool_address != address(0), "Zero address detected");

        require(xsd_pools[pool_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete xsd_pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < xsd_pools_array.length; i++){ 
            if (xsd_pools_array[i] == pool_address) {
                xsd_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit PoolRemoved(pool_address);
    }
// create a seperate function for users and the pool
    function burnpoolXSD(uint _xsdamount) public {
        require(msg.sender == router, "Only the router can access this function");
        require(totalSupply()-CollateralPool(payable(collateral_pool_address)).collat_XSD()>_xsdamount, "uXSD has to be positive");
        super._burn(address(xsdEthPool),_xsdamount);
        xsdEthPool.sync();
        emit XSDBurned(msg.sender, address(this), _xsdamount);
    }
    // add burn function for users
    function burnUserXSD(uint _xsdamount) public {
        require(totalSupply()-CollateralPool(payable(collateral_pool_address)).collat_XSD()>_xsdamount, "uXSD has to be positive");
        super._burn(msg.sender, _xsdamount);
        emit XSDBurned(msg.sender, address(this), _xsdamount);
    }
    function setXSDStep(uint256 _new_step) public onlyByOwnerPID {
        xsd_step = _new_step;

        emit XSDStepSet(_new_step);
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerPID {
        price_target = _new_price_target;

        emit PriceTargetSet(_new_price_target);
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerPID {
    	refresh_cooldown = _new_cooldown;

        emit RefreshCooldownSet(_new_cooldown);
    }

    function setTreasury(address _new_treasury) public onlyByOwner {
        require(_new_treasury != address(0), "Zero address detected");
        treasury = _new_treasury;
    }

    function setETHUSDOracle(address _eth_usd_oracle_address) public onlyByOwner {
        require(_eth_usd_oracle_address != address(0), "Zero address detected");

        eth_usd_oracle_address = _eth_usd_oracle_address;
        eth_usd_pricer = ChainlinkETHUSDPriceConsumer(eth_usd_oracle_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();

        emit ETHUSDOracleSet(_eth_usd_oracle_address);
    }
    
    function setXAGUSDOracle(address _xag_usd_oracle_address) public onlyByOwner {
        require(_xag_usd_oracle_address != address(0), "Zero address detected");

        xag_usd_oracle_address = _xag_usd_oracle_address;
        xag_usd_pricer = ChainlinkXAGUSDPriceConsumer(xag_usd_oracle_address);
        xag_usd_pricer_decimals = xag_usd_pricer.getDecimals();

        emit XAGUSDOracleSet(_xag_usd_oracle_address);
    }

    function setPIDController(address _pid_address) external onlyByOwner {
        require(_pid_address != address(0), "Zero address detected");

        pid_address = _pid_address;

        emit PIDControllerSet(_pid_address);
    }

    function setRouterAddress(address _router) external onlyByOwner {
        require(_router != address(0), "Zero address detected");
        router = _router;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwner {
        price_band = _price_band;

        emit PriceBandSet(_price_band);
    }

    // Sets the XSD_ETH Uniswap oracle address 
    function setXSDEthPool(address _xsd_pool_addr) public onlyByOwner {
        require(_xsd_pool_addr != address(0), "Zero address detected");
        xsdEthPool = IXSDWETHpool(_xsd_pool_addr); 

        emit XSDETHPoolSet(_xsd_pool_addr);
    }

    // Sets the BankX_ETH Uniswap oracle address 
    function setBankXEthPool(address _bankx_pool_addr) public onlyByOwner {
        require(_bankx_pool_addr != address(0), "Zero address detected");
        bankxEthPool = IBankXWETHpool(_bankx_pool_addr);

        emit BankXEthPoolSet(_bankx_pool_addr);
    }

    //sets the collateral pool address
    function setCollateralEthPool(address _collateral_pool_address) public onlyByOwner {
        require(_collateral_pool_address != address(0), "Zero address detected");
        collateral_pool_address = payable(_collateral_pool_address);
    }

    function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(_smartcontract_owner != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

    function renounceOwnership() external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        smartcontract_owner = address(0);
    }

    
    /* ========== EVENTS ========== */

    // Track XSD burned
    event XSDBurned(address indexed from, address indexed to, uint256 amount);

    // Track XSD minted
    event XSDMinted(address indexed from, address indexed to, uint256 amount);

    event CollateralRatioRefreshed(uint256 global_collateral_ratio);
    event PoolAdded(address pool_address);
    event PoolRemoved(address pool_address);
    event RedemptionFeeSet(uint256 red_fee);
    event MintingFeeSet(uint256 min_fee);
    event XSDStepSet(uint256 new_step);
    event PriceTargetSet(uint256 new_price_target);
    event RefreshCooldownSet(uint256 new_cooldown);
    event ETHUSDOracleSet(address eth_usd_oracle_address);
    event XAGUSDOracleSet(address xag_usd_oracle_address);
    event PIDControllerSet(address _pid_controller);
    event PriceBandSet(uint256 price_band);
    event XSDETHPoolSet(address xsd_pool_addr);
    event BankXEthPoolSet(address bankx_pool_addr);
    event CollateralRatioToggled(bool collateral_ratio_paused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRouter{
    function creatorAddLiquidityTokens(
        address tokenB,
        uint amountB,
        uint deadline
    ) external;

    function creatorAddLiquidityETH(
        address pool,
        uint deadline
    ) external payable;

    function userAddLiquidityETH(
        address pool,
        uint deadline
    ) external payable;

    function userRedeemLiquidity(
        address pool,
        uint deadline
    ) external;

    function swapETHForXSD(uint amountOut,uint deadline) external payable;

    function swapXSDForETH(uint amountOut, uint amountInMax, uint deadline) external;

    function swapETHForBankX(uint amountOut, uint deadline) external payable;
    
    function swapBankXForETH(uint amountOut, uint amountInMax, uint deadline) external;

    function swapBankXForXSD(uint bankx_amount, address sender, uint256 eth_min_amount, uint256 bankx_min_amount, uint256 deadline) external;

    function swapXSDForBankX(uint XSD_amount, address sender, uint256 eth_min_amount, uint256 xsd_min_amount, uint256 deadline) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library CollateralPoolLibrary {
    // ================ Structs ================
    // Needed to lower stack size
    struct MintFF_Params {
        uint256 bankx_price_usd; 
        uint256 col_price_usd;
        uint256 bankx_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackBankX_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 bankx_price_usd;
        uint256 col_price_usd;
        uint256 BankX_amount;
    }

    struct BuybackXSD_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 xsd_price_usd;
        uint256 col_price_usd;
        uint256 XSD_amount;
    }



    // ================ Functions ================
// xsd is at the price of one gram of silver.
    function calcMint1t1XSD(uint256 col_price, uint256 silver_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        return (collateral_amount_d18*(col_price))/(gram_price); 
    }
// xsd is at the price of one gram of silver
    function calcMintAlgorithmicXSD(uint256 bankx_price_usd, uint256 silver_price, uint256 bankx_amount_d18) public pure returns (uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        return (bankx_amount_d18*bankx_price_usd)/(gram_price);
    }

    function calcMintInterest(uint256 XSD_amount,uint256 silver_price,uint256 rate, uint256 accum_interest, uint256 interest_rate, uint256 time, uint256 amount) internal view returns(uint256, uint256, uint256, uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        if(time == 0){
        interest_rate = rate;
        amount = XSD_amount;
        time = block.timestamp;
        }
        else{
        uint delta_t = block.timestamp - time;
        delta_t = delta_t/(86400); 
        accum_interest = accum_interest+((amount*gram_price*interest_rate*delta_t)/(365*(1e12)));
    
        interest_rate = (amount*interest_rate) + (XSD_amount*rate);
        amount = amount+XSD_amount;
        interest_rate = interest_rate/amount;
        time = block.timestamp;
        }
        return (
            accum_interest,
            interest_rate,
            time, 
            amount
        );
    }

    function calcRedemptionInterest(uint256 XSD_amount,uint256 silver_price, uint256 accum_interest, uint256 interest_rate, uint256 time, uint256 amount) internal view returns(uint256, uint256, uint256, uint256){
        uint256 gram_price = (silver_price*(1e4))/(311035);
        uint delta_t = block.timestamp - time;
        delta_t = delta_t/(86400);
        accum_interest = accum_interest+((amount*gram_price*interest_rate*delta_t)/(365*(1e12)));
        amount = amount - XSD_amount;
        time = block.timestamp;
        return (
            accum_interest,
            interest_rate,
            time, 
            amount
        );
    }
    
    // Must be internal because of the struct
    // xsd must be the dollar value of one price of silver
    function calcMintFractionalXSD(MintFF_Params memory params) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint XSD. We do this by seeing the minimum mintable XSD based on each amount 
        uint256 bankx_dollar_value_d18;
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the BankX
            bankx_dollar_value_d18 = params.bankx_amount*(params.bankx_price_usd)/(1e6);
            c_dollar_value_d18 = params.collateral_amount*(params.col_price_usd)/(1e6);

        }
        uint calculated_bankx_dollar_value_d18 = 
                    (c_dollar_value_d18*(1e6)/(params.col_ratio))
                    -(c_dollar_value_d18);

        uint calculated_bankx_needed = calculated_bankx_dollar_value_d18*(1e6)/(params.bankx_price_usd);

        return (
            (c_dollar_value_d18+calculated_bankx_dollar_value_d18),
            calculated_bankx_needed
        );
    }

    function calcRedeem1t1XSD(uint256 col_price_usd,uint256 silver_price, uint256 XSD_amount) public pure returns (uint256,uint256) {
        uint256 gram_price = (silver_price*(1e4))/(311035);
        return ((XSD_amount*gram_price/1e6),((XSD_amount*gram_price)/col_price_usd));
    }

    // Must be internal because of the struct
    function calcBuyBackBankX(BuybackBankX_Params memory params) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible BankX with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 bankx_dollar_value_d18 = (params.BankX_amount*params.bankx_price_usd);
        require((bankx_dollar_value_d18/1e6) <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of BankX provided 
        uint256 collateral_equivalent_d18 = (bankx_dollar_value_d18)/(params.col_price_usd);
        //collateral_equivalent_d18 = collateral_equivalent_d18-((collateral_equivalent_d18*(params.buyback_fee))/(1e6));

        return (
            collateral_equivalent_d18
        );

    }

    function calcBuyBackXSD(BuybackXSD_Params memory params) internal pure returns (uint256) {
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        uint256 xsd_dollar_value_d18 = params.XSD_amount*(params.xsd_price_usd);
        require((xsd_dollar_value_d18/1e6) <= params.excess_collateral_dollar_value_d18, "You are trying to buy more than the excess!");

        uint256 collateral_equivalent_d18 = (xsd_dollar_value_d18)/(params.col_price_usd);

        return (
            collateral_equivalent_d18
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPIDController{
    function bucket1() external view returns (bool);
    function bucket2() external view returns (bool);
    function bucket3() external view returns (bool);
    function diff1() external view returns (uint);
    function diff2() external view returns (uint);
    function diff3() external view returns (uint);
    function amountpaid1() external view returns (uint);
    function amountpaid2() external view returns (uint);
    function amountpaid3() external view returns (uint);
    function bankx_updated_price() external view returns (uint);
    function xsd_updated_price() external view returns (uint);
    function systemCalculations() external;
    struct PriceCheck{
        uint256 lastpricecheck;
        bool pricecheck;
    }
    function lastPriceCheck(address user) external view returns (PriceCheck memory info);
    function amountPaidBankXWETH(uint ethvalue) external;
    function amountPaidXSDWETH(uint ethvalue) external;
    function amountPaidCollateralPool(uint ethvalue) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../ERC20/ERC20Custom.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../XSD/XSDStablecoin.sol";

contract BankXToken is ERC20Custom {

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    
    
    uint256 public genesis_supply; // 2B is printed upon genesis
    address public pool_address; //points to BankX pool address
    address public treasury; //stores the genesis supply
    address public router;
    XSDStablecoin private XSD; //XSD stablecoin instance
    address public smartcontract_owner;
    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(XSD.xsd_pools(msg.sender) == true, "Only xsd pools can mint new BankX");
        _;
    } 
    
    modifier onlyByOwner() {
        require(msg.sender == smartcontract_owner, "You are not an owner");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pool_amount, 
        uint256 _genesis_supply,
        address _treasury,
        address _smartcontract_owner
    ) {
        require((_treasury != address(0)), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        genesis_supply = _genesis_supply + _pool_amount;
        treasury = _treasury;
        _mint(_msgSender(), _pool_amount);
        _mint(treasury, _genesis_supply);
        smartcontract_owner = _smartcontract_owner;

    
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setPool(address new_pool) external onlyByOwner {
        require(new_pool != address(0), "Zero address detected");

        pool_address = new_pool;
    }

    function setTreasury(address new_treasury) external onlyByOwner {
        require(new_treasury != address(0), "Treasury address cannot be 0");
        treasury = new_treasury;
    }

    function setRouterAddress(address _router) external onlyByOwner {
        require(_router != address(0), "Zero address detected");
        router = _router;
    }
    
    function setXSDAddress(address xsd_contract_address) external onlyByOwner {
        require(xsd_contract_address != address(0), "Zero address detected");

        XSD = XSDStablecoin(xsd_contract_address);

        emit XSDAddressSet(xsd_contract_address);
    }
    
    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
        emit BankXMinted(address(this), to, amount);
    }
    
    function genesisSupply() public view returns(uint256){
        return genesis_supply;
    }

    // This function is what other xsd pools will call to mint new BankX (similar to the XSD mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools  {        
        super._mint(m_address, m_amount);
        emit BankXMinted(address(this), m_address, m_amount);
    }

    // This function is what other xsd pools will call to burn BankX 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {

        super._burnFrom(b_address, b_amount);
        emit BankXBurned(b_address, address(this), b_amount);
    }
    //burn bankx from the pool when bankx is inflationary
    function burnpoolBankX(uint _bankx_amount) public {
        require(msg.sender == router, "Only Router can access this function");
        require(totalSupply()>genesis_supply,"BankX must be deflationary");
        super._burn(pool_address, _bankx_amount);
        IBankXWETHpool(pool_address).sync();
        emit BankXBurned(msg.sender, address(this), _bankx_amount);
    }

    function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(_smartcontract_owner != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

    function renounceOwnership() external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        smartcontract_owner = address(0);
    }
    /* ========== EVENTS ========== */

    // Track BankX burned
    event BankXBurned(address indexed from, address indexed to, uint256 amount);

    // Track BankX minted
    event BankXMinted(address indexed from, address indexed to, uint256 amount);
    event XSDAddressSet(address addr);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Due to compiling issues, _name, _symbol, and _decimals were removed


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Custom is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
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
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Transfers 'tokens' from 'account' to origin address, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkETHUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;
    //Arbitrum: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
    //Ethereum: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    constructor() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID
            , 
            int price,
            ,
            ,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        require(answeredInRound >= roundID);
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkXAGUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;

    //Arbitrum: 0xC56765f04B248394CF1619D20dB8082Edbfa75b1
    //Ethereum: 0x379589227b15F1a12195D3f2d90bBc9F31f95235
    constructor() {
        priceFeed = AggregatorV3Interface(0x379589227b15F1a12195D3f2d90bBc9F31f95235);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID
            , 
            int price,
            ,
            ,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        require(answeredInRound >= roundID);
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}