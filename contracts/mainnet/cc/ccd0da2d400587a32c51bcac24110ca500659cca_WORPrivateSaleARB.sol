/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// SPDX-License-Identifier: MIT

/*

    WOR token contract

    World of Rewards (WOR) is a rewards platform
    based on blockchains that aims to create an ecosystem
    decentralized, transparent, and
    fair reward system for users.
    The project is based on the BSC blockchain and uses
    smart contracts to automate the distribution of rewards.

    https://worldofrewards.finance/
    https://twitter.com/WorldofRewards
    https://t.me/WorldofRewards



*/


pragma solidity 0.8.18;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
*/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner(){
        require(newOwner != address(0), "Is impossible to renounce the ownership of the contract");
        require(newOwner != address(0xdead), "Is impossible to renounce the ownership of the contract");

        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}


interface IERC20Metadata {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

}


interface IUniswapV2Router02 {

    function getAmountsOut(
        uint amountIn, 
        address[] calldata path) 
        external view returns (uint[] memory amounts);

}


contract ERC20 is Context, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

}

contract WORPrivateSaleARB is ERC20, Ownable, ReentrancyGuard {

    uint256 public timeDeployContract;

    uint256 public percent;
    uint256 public priceARB;
    uint256 public priceBNB;
    uint256 public priceUSD;
    uint256 public denominatorUSD;

    //As the sale is in more than one cryptocurrency
    //so there will be a difference due to ARB or to ARB conversion spreeds
    uint256 public errorMargin;

    //Private sale limit
    uint256 public hardCapPrivateSale;

    uint256 public minARBbuy;
    uint256 public maxARBbuy;

    //Stats here
    //Number of purchases in private
    uint256 public count;
    //All ARB purchases are added to this variable
    uint256 public totalARBpaid;
    //All USD purchases are added to this variable
    uint256 public totalUSDpaid;

    //All tokens sold in private
    //Tokens sold without adding the private sale bonus
    uint256 public totalTokensWOR;

    //Total amount sold equivalent in ARB
    uint256 public totalSoldInARB;
    //Total sold amount equivalent in USD
    uint256 public totalSoldInUSD;

    bool public isOpenPrivateSale;

    uint256 public restARBfees;

    address public uniswapV2Router      = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public addressUSDC          = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public addressBridgedUSDC   = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public addressUSDT          = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public addressWETH          = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public addressWOR           = 0x54Ffa903E7E80b9a3c8861B5BcbADFF370670A58;

    address public privateSaleReceiver    = payable(0x7987F8EE96FAD1f24EC199C63052388569705A62);
    address public privateSaleTokens    = payable(0x15aF2B7dACc6b5B22C7F09F01b71394d45e25474);
    address public projectWallet    = payable(0xd8D65AE7b47e4F6DF5864BcbAce9fb2DEC322c4D);

    address public authWallet = 0x80705234b34b5E02a75ABe9a268713bcED8AfE72;

    struct structBuy {
        //All tokens that a uer bought
        uint256 amountTokenPurchased;
        //Only the amounts in ARB that the user has paid
        uint256 amountARBpaid;
        //Only the values in USDC that the user paid
        uint256 amountUSDCpaid;
        //Only the amounts in USDT that the user paid
        uint256 amountUSDTpaid;
        //Conversion of USD to ARB added to the ARB paid in this PrivateSale
        uint256 amountARBPaidConverted;
        //Conversion of ARB to USD added to the USD paid in this PrivateSale
        uint256 amountUSDPaidConverted;
    }

    mapping (address => structBuy) mappingStructBuy;

    receive() external payable 
    {}

    constructor() ERC20("WOR (PrivateSale ARB)", "") {
        timeDeployContract = block.timestamp;
        isOpenPrivateSale = true;

        priceARB = 630000;
        priceBNB = 89013;
        priceUSD = 275238;
        denominatorUSD = 100000000;
        percent = 25;

        errorMargin = 110;

        restARBfees = 1 * 10 ** 18 / 10000;

        hardCapPrivateSale = 10 * 10 ** 18;

        //Setting to avoid rollback in convert call to getLimitToBuy_USD
        totalSoldInARB = 1;

        minARBbuy = 6 * 10 ** 18 / 1000;
        maxARBbuy = 3 * 10 ** 18 / 10;

        _mint(address(0), 1);
    }

    modifier onlyAuth() {
        require(msg.sender == authWallet, "Caller is not Auth Wallet");
        _;
    }

    function maxUSDbuy() public view returns (uint256) {
        return convert(addressWETH, addressUSDT, maxARBbuy);
    }

    function minUSDbuy() public view returns (uint256) {
        return convert(addressWETH, addressUSDT, minARBbuy);
    }

    function getTokensOut_ARB(uint256 amountIn) public view returns (uint256) {
        return amountIn * priceARB;
    }

    function getTokensOut_USD(uint256 amountIn) public view returns (uint256) {
        return (amountIn / priceUSD) * denominatorUSD;
    }

    function getMappingStructBuy(address buyer) public view returns (structBuy memory) {
        return mappingStructBuy[buyer];
    }

    function getLimitToBuy_ARB(address buyer) public view returns (uint256 limit) {

        //It is redundant and unnecessary to check, but we do these rechecks
        if (maxARBbuy >= mappingStructBuy[buyer].amountARBPaidConverted) {
            limit = maxARBbuy - mappingStructBuy[buyer].amountARBPaidConverted;

        } else {
            limit = 0;
        }

        if (limit > hardCapPrivateSale - totalSoldInARB) limit = hardCapPrivateSale - totalSoldInARB;

        if (address(buyer).balance > restARBfees) {
            if (limit > address(buyer).balance - restARBfees) 
                limit = address(buyer).balance - restARBfees;
        }

        return limit;

    }

    function getLimitToBuy_USD(address buyer) public view returns (uint256 limit) {

        uint256 maxARBbuyConverted = convert(addressWETH, addressUSDT, maxARBbuy);
        uint256 hardCapPrivateSaleConverted = convert(addressWETH, addressUSDT, hardCapPrivateSale);
        uint256 totalSoldInARBConverted = convert(addressWETH, addressUSDT, totalSoldInARB);
        //It is redundant and unnecessary to check, but we do these rechecks
        if (maxARBbuyConverted >= mappingStructBuy[buyer].amountUSDPaidConverted) {
            limit = maxARBbuyConverted - mappingStructBuy[buyer].amountUSDPaidConverted;

        } else {
            limit = 0;
        }

        if (limit > hardCapPrivateSaleConverted - totalSoldInARBConverted) 
        limit = hardCapPrivateSaleConverted - totalSoldInARBConverted;

        return limit;

    }

    function convert(address addressIn, address addressOut, uint256 amount) public view returns (uint256) {
        
        address[] memory path = new address[](2);
        path[0] = addressIn;
        path[1] = addressOut;

        uint256[] memory amountOutMins = 
        IUniswapV2Router02(uniswapV2Router).getAmountsOut(amount, path);

        return amountOutMins[path.length -1];
    } 


    function buyPrivateSaleByARB() 
        external payable nonReentrant() {
        
        require(isOpenPrivateSale, "PrivateSale not opened yet");
        require(totalSoldInARB <= hardCapPrivateSale, "Sales limit reached");

        uint256 amountARB = msg.value;
        uint256 amountUSDconverted = convert(addressWETH, addressUSDT, amountARB);

        unchecked {
            require(minARBbuy <= amountARB, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountARBPaidConverted + amountARB 
                    <= maxARBbuy * errorMargin / 100);
        
            uint256 amountBuy = amountARB * priceARB;

            IERC20(addressWOR).transferFrom(privateSaleTokens, msg.sender, amountBuy);

            //amountARB is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself        
            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountARBpaid += amountARB;
            mappingStructBuy[_msgSender()].amountARBPaidConverted += amountARB;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDconverted;

            count ++;
            totalARBpaid += amountARB;
            totalTokensWOR += amountBuy;
            
            totalSoldInARB += amountARB;
            totalSoldInUSD += amountUSDconverted;

            (bool success1,) = privateSaleReceiver.call{value: amountARB * (100 - percent) / 100}("");
            require(success1, "Failed to send ARB");

            (bool success2,) = projectWallet.call{value: address(this).balance}("");
            require(success2, "Failed to send ARB");
        }
    }

    //You have to approve the token first
    function buyPrivateSaleByUSDC(uint256 amountUSDC)
        external nonReentrant() {
        require(isOpenPrivateSale, "PrivateSale not opened yet");
        require(totalSoldInARB <= hardCapPrivateSale, "Sales limit reached");

        uint256 amountARBconverted = convert(addressBridgedUSDC, addressWETH, amountUSDC);

        unchecked {
            require(minARBbuy <= amountARBconverted, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountARBPaidConverted + 
            amountARBconverted <= maxARBbuy * errorMargin / 100);

            uint256 amountBuy = (amountUSDC / priceUSD) * denominatorUSD;

            IERC20(addressUSDC).transferFrom(msg.sender, privateSaleReceiver, amountUSDC * (100 - percent) / 100);
            IERC20(addressUSDC).transferFrom(msg.sender, projectWallet, amountUSDC * (percent) / 100);

            //amountUSDC is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself
            IERC20(addressWOR).transferFrom(privateSaleTokens, msg.sender, amountBuy * 10 ** 12);

            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountUSDCpaid += amountUSDC;
            mappingStructBuy[_msgSender()].amountARBPaidConverted += amountARBconverted;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDC;

            count ++;
            totalUSDpaid += amountUSDC;
            totalTokensWOR += amountBuy;

            totalSoldInARB += amountARBconverted;
            totalSoldInUSD += amountUSDC;
        }
    }

    //You have to approve the token first
    function buyPrivateSaleByBridgedUSDC(uint256 amountBridgedUSDC)
        external nonReentrant() {
        require(isOpenPrivateSale, "PrivateSale not opened yet");
        require(totalSoldInARB <= hardCapPrivateSale, "Sales limit reached");

        uint256 amountARBconverted = convert(addressBridgedUSDC, addressWETH, amountBridgedUSDC);

        unchecked {
            require(minARBbuy <= amountARBconverted, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountARBPaidConverted + 
            amountARBconverted <= maxARBbuy * errorMargin / 100);

            uint256 amountBuy = (amountBridgedUSDC / priceUSD) * denominatorUSD;

            IERC20(addressBridgedUSDC).transferFrom(msg.sender, privateSaleReceiver, amountBridgedUSDC * (100 - percent) / 100);
            IERC20(addressBridgedUSDC).transferFrom(msg.sender, projectWallet, amountBridgedUSDC * (percent) / 100);

            //amountUSDC is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself
            IERC20(addressWOR).transferFrom(privateSaleTokens, msg.sender, amountBuy * 10 ** 12);

            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountUSDCpaid += amountBridgedUSDC;
            mappingStructBuy[_msgSender()].amountARBPaidConverted += amountARBconverted;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountBridgedUSDC;

            count ++;
            totalUSDpaid += amountBridgedUSDC;
            totalTokensWOR += amountBuy;

            totalSoldInARB += amountARBconverted;
            totalSoldInUSD += amountBridgedUSDC;
        }
    }

    //You have to approve the token first
    function buyPrivateSaleByUSDT(uint256 amountUSDT)
        external nonReentrant() {
        require(isOpenPrivateSale, "PrivateSale not opened yet");
        require(totalSoldInARB <= hardCapPrivateSale, "Sales limit reached");

        uint256 amountARBconverted = convert(addressUSDT, addressWETH, amountUSDT);

        unchecked {
            require(minARBbuy <= amountARBconverted, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountARBPaidConverted + 
            amountARBconverted <= maxARBbuy * errorMargin / 100);

            uint256 amountBuy = (amountUSDT / priceUSD) * denominatorUSD;

            IERC20(addressUSDT).transferFrom(msg.sender, privateSaleReceiver, amountUSDT * (100 - percent) / 100);
            IERC20(addressUSDT).transferFrom(msg.sender, projectWallet, amountUSDT * (percent) / 100);

            //addressUSDT is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself
            IERC20(addressWOR).transferFrom(privateSaleTokens, msg.sender, amountBuy * 10 ** 12);

            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountUSDTpaid += amountUSDT;
            mappingStructBuy[_msgSender()].amountARBPaidConverted += amountARBconverted;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDT;

            count ++;
            totalUSDpaid += amountUSDT;
            totalTokensWOR += amountBuy;

            totalSoldInARB += amountARBconverted;
            totalSoldInUSD += amountUSDT;

        }

    }


    function buyPrivateSaleByBSC_BNB(address account, uint256 amountBNB) 
        external nonReentrant() onlyAuth() {
        
        require(isOpenPrivateSale, "PrivateSale not opened yet");
        // require(totalSoldInARB <= hardCapPrivateSale, "Sales limit reached");

        // uint256 amountARB = msg.value;
        // uint256 amountUSDconverted = convert(addressWETH, addressUSDC, amountARB);

        unchecked {
            // require(minARBbuy <= amountARB, "Minimum purchase");
            // require(mappingStructBuy[_msgSender()].amountARBPaidConverted + amountARB 
            //         <= maxARBbuy * errorMargin / 100);
        
            uint256 amountBuy = amountBNB * priceBNB;

            IERC20(addressWOR).transferFrom(privateSaleTokens, account, amountBuy);

            //amountARB is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself        
            // mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            // mappingStructBuy[_msgSender()].amountARBpaid += amountARB;
            // mappingStructBuy[_msgSender()].amountARBPaidConverted += amountARB;
            // mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDconverted;

            // count ++;
            // totalARBpaid += amountARB;
            // totalTokensWOR += amountBuy;
            
            // totalSoldInARB += amountARB;
            // totalSoldInUSD += amountUSDconverted;

            // (bool success1,) = privateSaleReceiver.call{value: amountARB * (100 - percent) / 100}("");
            // require(success1, "Failed to send ARB");

            // (bool success2,) = projectWallet.call{value: address(this).balance}("");
            // require(success2, "Failed to send ARB");
        }
    }


    //The backend calls this function when it hears paid USDT on the BSC network
    //Paid USDT is deposited into a project's BSC account    
    function buyPrivateSaleByBSC_USD(address account, uint256 amountUSD)
        external nonReentrant() onlyAuth() {
        require(isOpenPrivateSale, "PrivateSale not opened yet");
        // require(totalSoldInARB <= hardCapPrivateSale, "Sales limit reached");

        // uint256 amountARBconverted = convert(addressUSDT, addressWETH, amountUSDT);

        unchecked {
            // require(minARBbuy <= amountARBconverted, "Minimum purchase");
            // require(mappingStructBuy[_msgSender()].amountARBPaidConverted + 
            // amountARBconverted <= maxARBbuy * errorMargin / 100);

            uint256 amountBuy = (amountUSD / priceUSD) * denominatorUSD;

            // IERC20(addressUSDT).transferFrom(msg.sender, privateSaleReceiver, amountUSDT * (100 - percent) / 100);
            // IERC20(addressUSDT).transferFrom(msg.sender, projectWallet, amountUSDT * (percent) / 100);

            //addressUSDT is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself
            IERC20(addressWOR).transferFrom(privateSaleTokens, account, amountBuy * 10 ** 12);

            // mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            // mappingStructBuy[_msgSender()].amountUSDTpaid += amountUSDT;
            // mappingStructBuy[_msgSender()].amountARBPaidConverted += amountARBconverted;
            // mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDT;

            // count ++;
            // totalUSDpaid += amountUSDT;
            // totalTokensWOR += amountBuy;

            // totalSoldInARB += amountARBconverted;
            // totalSoldInUSD += amountUSDT;

        }

    }

    function balanceARB () external onlyOwner(){
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function balanceERC20 (address token) external onlyOwner(){
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setPercent (uint256 _percent) external onlyOwner(){
        percent = _percent;
    }

    function setLimits(uint256 _minARBbuy, uint256 _maxARBbuy) external onlyOwner(){
        minARBbuy = _minARBbuy;
        maxARBbuy = _maxARBbuy;
    }

    function setIsOpenPrivateSale (bool _isOpenPrivateSale) external onlyOwner(){
        isOpenPrivateSale = _isOpenPrivateSale;
    }

    function setHardCapPrivateSale (uint256 _hardCapPrivateSale) external onlyOwner(){
        hardCapPrivateSale = _hardCapPrivateSale;
    }

    function setErrorMargin (uint256 _errorMargin) external onlyOwner(){
        errorMargin = _errorMargin;
    }

    function setRestARBfees (uint256 _restARBfees) external onlyOwner(){
        restARBfees = _restARBfees;
    }

    function setPrices (
        uint256 _priceARB,
        uint256 _priceUSD) external onlyOwner(){

        priceARB = _priceARB;
        priceUSD = _priceUSD;
    }

    function setAuthWallet(address _authWallet) external onlyOwner() {
        authWallet = _authWallet;
    }

    function setAddressWOR(address _addressWOR) external onlyOwner() {
        addressWOR = _addressWOR;
    }

    function setAddresses(
        address _uniswapV2Router,
        address _addressUSDC,
        address _addressBridgedUSDC,
        address _addressUSDT,
        address _addressWETH,
        address _addressWOR
        ) external onlyOwner() {

        uniswapV2Router      = _uniswapV2Router;
        addressUSDC          = _addressUSDC;
        addressBridgedUSDC   = _addressBridgedUSDC;
        addressUSDT          = _addressUSDT;
        addressWETH          = _addressWETH;
        addressWOR           = _addressWOR;
    }

}