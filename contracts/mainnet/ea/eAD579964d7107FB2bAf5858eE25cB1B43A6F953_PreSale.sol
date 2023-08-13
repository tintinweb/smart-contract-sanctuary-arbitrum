/**
 *Submitted for verification at Arbiscan on 2023-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface INFT {
    function mint(address to, uint256 num) external;
}

interface IMintPool {
    function _invitor(address account) external view returns (address invitor);

    function bindInvitor(address account, address invitor) external;

    function getBinderLength(address account) external view returns (uint256);

    function addUserAmount(address account, uint256 amount, bool calInvite) external;
}

abstract contract AbsPreSale is Ownable {
    struct UserInfo {
        uint256 buyAmount;
        uint256 binderBuyNum;
        bool giveNFT;
    }

    mapping(address => UserInfo) private _userInfo;

    uint256 private _saleQty = 3000;//
    uint256 private _pricePerSale;
    uint256 private _mintAmountPerSale;

    //
    address public _cashAddress;
    address private _usdtAddress;
    address public _nftAddress;

    bool private _pauseBuy = true;
    uint256 private _nftCondition;
    uint256 public _nftQty = 600;
    IMintPool public _mintPool;

    uint256 private _saleSoldAmount;//
    uint256 private _totalUsdt;
    uint256 public _nftNum;

    constructor(address CashAddress, address USDTAddress, address NFTAddress, address MintPool){
        _cashAddress = CashAddress;
        _usdtAddress = USDTAddress;
        _nftAddress = NFTAddress;
        uint256 usdtUnit = 10 ** IERC20(USDTAddress).decimals();
        _pricePerSale = 300 * usdtUnit;
        _nftCondition = 5;
        _mintPool = IMintPool(MintPool);
        _mintAmountPerSale = 1000 * usdtUnit;
    }

    function buy(address invitor) external {
        require(!_pauseBuy, "pauseBuy");
        address account = msg.sender;
        _mintPool.bindInvitor(account, invitor);
        UserInfo storage userInfo = _userInfo[account];
        require(0 == userInfo.buyAmount, "bought");
        require(_saleQty > _saleSoldAmount, "soldOut");
        _saleSoldAmount += 1;

        _buy(account, _pricePerSale);
    }

    function _buy(address account, uint256 usdtAmount) private {
        address invitor = _mintPool._invitor(account);
        UserInfo storage invitorInfo = _userInfo[invitor];
        invitorInfo.binderBuyNum += 1;
        if (!invitorInfo.giveNFT && invitorInfo.binderBuyNum >= _nftCondition && _nftQty > _nftNum) {
            _nftNum += 1;
            invitorInfo.giveNFT = true;
            _giveNFT(invitor);
        }

        _totalUsdt += usdtAmount;

        UserInfo storage userInfo = _userInfo[account];
        userInfo.buyAmount += usdtAmount;

        _takeToken(_usdtAddress, account, _cashAddress, usdtAmount);
        _mintPool.addUserAmount(account, _mintAmountPerSale, false);
    }

    function _giveNFT(address invitor) private {
        INFT(_nftAddress).mint(invitor, 1);
    }

    function getSaleInfo() external view returns (
        address usdtAddress, uint256 usdtDecimals, string memory usdtSymbol,
        uint256 pricePerSale, uint256 qty, uint256 soldNum, uint256 totalUsdt,
        uint256 mintAmountPerSale, bool pauseBuy, uint256 nftCondition
    ) {
        usdtAddress = _usdtAddress;
        usdtDecimals = IERC20(usdtAddress).decimals();
        usdtSymbol = IERC20(usdtAddress).symbol();
        qty = _saleQty;
        soldNum = _saleSoldAmount;
        totalUsdt = _totalUsdt;
        pricePerSale = _pricePerSale;
        mintAmountPerSale = _mintAmountPerSale;
        pauseBuy = _pauseBuy;
        nftCondition = _nftCondition;
    }

    function getUserInfo(address account) external view returns (
        uint256 buyAmount,
        uint256 binderBuyNum,
        bool isGiveNFT,
        uint256 usdtBalance,
        uint256 usdtAllowance,
        address invitor
    ) {
        UserInfo storage userInfo = _userInfo[account];
        buyAmount = userInfo.buyAmount;
        binderBuyNum = userInfo.binderBuyNum;
        isGiveNFT = userInfo.giveNFT;
        usdtBalance = IERC20(_usdtAddress).balanceOf(account);
        usdtAllowance = IERC20(_usdtAddress).allowance(account, address(this));
        invitor = _mintPool._invitor(account);
    }

    receive() external payable {}

    function setQty(uint256 q) external onlyOwner {
        _saleQty = q;
    }

    function setMintAmountPerSale(uint256 a) external onlyOwner {
        _mintAmountPerSale = a;
    }

    function setPricePerSale(uint256 amount) external onlyOwner {
        _pricePerSale = amount;
    }

    function setNftCondition(uint256 c) external onlyOwner {
        _nftCondition = c;
    }

    function setNftQty(uint256 q) external onlyOwner {
        _nftQty = q;
    }

    function setUsdtAddress(address adr) external onlyOwner {
        _usdtAddress = adr;
    }

    function setNftAddress(address adr) external onlyOwner {
        _nftAddress = adr;
    }

    function setCashAddress(address adr) external onlyOwner {
        _cashAddress = adr;
    }

    function setMintPool(address adr) external onlyOwner {
        _mintPool = IMintPool(adr);
    }

    function setPauseBuy(bool pause) external onlyOwner {
        _pauseBuy = pause;
    }

    function claimBalance(address to, uint256 amount) external onlyOwner {
        safeTransferETH(to, amount);
    }

    function claimToken(address token, address to, uint256 amount) external onlyOwner {
        safeTransfer(token, to, amount);
    }

    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'AF');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETF');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TFF');
    }

    function _giveToken(address tokenAddress, address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "PTNE");
        safeTransfer(tokenAddress, account, amount);
    }

    function _takeToken(address tokenAddress, address from, address to, uint256 tokenNum) private {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(from)) >= tokenNum, "TNE");
        safeTransferFrom(tokenAddress, from, to, tokenNum);
    }
}

contract PreSale is AbsPreSale {
    constructor() AbsPreSale(
    //Cash
        address(0x1312dc96073F34373ee9E79288854C2f37272eD6),
    //USDT
        address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9),
    //NFT
        address(0xF0c987A22170FEe55d62bd2cd6ED8c047b8F418E),
    //MintPool
        address(0xE90EFCFAaD109d9059331F2fF0A2dB5a72ACdEac)
    ){

    }
}