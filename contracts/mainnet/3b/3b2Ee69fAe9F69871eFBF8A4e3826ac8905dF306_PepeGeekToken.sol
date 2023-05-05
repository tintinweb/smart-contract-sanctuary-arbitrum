pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract PepeGeekToken is Context, Ownable, IERC20, ERC20Detailed {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniSwapV2Router;
    address public immutable uniSwapV2Pair;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax;

    uint256 internal _totalSupply;

    uint256 public sellFee = 4;
    uint256 public buyFee = 4;
    uint256 private marketingFee;

    uint256 public feeDev = 10;
    uint256 public feeMarketing = 10;
    uint256 public feeJackpot = 20;

    uint256 public constant ONE_HUNDRED_PERCENT = 100;

    address payable public walletMarketing =
        payable(0x3CF385500744eACDbE6b91026a87A09D60C74D6C);
    address payable public walletDev =
        payable(0x9b4AccaFBaC7947d23F86A30B2E11c4B299E3950);
    address payable public walletJackpot =
        payable(0xf80d55083704130ca3EC4515887c5c91df2c1AF9);

    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    bool public tradingEnabled = false;

    uint256 public numTokensSellToFee = 1 * 10 ** 18;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    address private _owner;

    uint256 public maxWallet;

    constructor() ERC20Detailed("Pepe Geek Token", "GPT", 18) {
        _owner = msg.sender;
        _totalSupply = 777777 * (10 ** 18);

        _balances[_owner] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        uniSwapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniSwapV2Router = _uniswapV2Router;

        maxWallet = (_totalSupply * 1) / 100;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[walletMarketing] = true;
        _isExcludedFromFee[walletJackpot] = true;
        //exclude owner and liquidity contract from max supply
        _isExcludedFromMax[uniSwapV2Pair] = true;
        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address towner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[towner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function setBuyFeePercent(uint256 newFee) external onlyOwner {
        require(newFee <= 4, "Buy fee should be less than 4%");
        buyFee = newFee;
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        tradingEnabled = true;
    }

    function setSellFeePercent(uint256 newFee) external onlyOwner {
        require(newFee <= 4, "Sell fee should be less than 4%");
        sellFee = newFee;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (!_isExcludedFromMax[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function setFees(
        uint256 jackpot,
        uint256 marketing,
        uint256 dev
    ) external onlyOwner {
        require(jackpot + marketing + dev == ONE_HUNDRED_PERCENT);
        feeJackpot = jackpot;
        feeMarketing = marketing;
        feeDev = dev;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= totalSupply() / 100);
        maxWallet = (_totalSupply * amount) / 100;
    }

    function setWalletMarketing(address payable wallet) external onlyOwner {
        require(
            wallet != walletMarketing,
            "walletMarketing wallet is already that address"
        );
        require(
            !isContract(wallet),
            "walletMarketing wallet cannot be a contract"
        );
        require(wallet != address(0), "Can't set to dead address!");
        walletMarketing = wallet;
    }

    function setWalletDev(address payable wallet) external onlyOwner {
        require(
            wallet != walletDev,
            "walletDev wallet is already that address"
        );
        require(!isContract(wallet), "walletDev wallet cannot be a contract");
        require(wallet != address(0), "Can't set to dead address!");
        walletDev = wallet;
    }

    function setWalletJackpot(address payable wallet) external onlyOwner {
        require(
            wallet != walletJackpot,
            "walletJackpot wallet is already that address"
        );
        require(
            !isContract(wallet),
            "walletJackpot wallet cannot be a contract"
        );
        require(wallet != address(0), "Can't set to dead address!");
        _isExcludedFromFee[walletJackpot] = false;
        walletJackpot = wallet;
        _isExcludedFromFee[wallet] = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeNumTokensSellToFee(
        uint256 _numTokensSellToFee
    ) external onlyOwner {
        require(
            _numTokensSellToFee >= 1 * 10 ** 18 &&
                _numTokensSellToFee <= 10000000 * 10 ** 18,
            "Threshold must be set within 1 to 10,000,000 tokens"
        );
        numTokensSellToFee = _numTokensSellToFee;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromMax(address account) public onlyOwner {
        _isExcludedFromMax[account] = true;
    }

    function includeInMax(address account) public onlyOwner {
        _isExcludedFromMax[account] = false;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        checkWalletLimit(recipient, amount);

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToFee;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniSwapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        } else {
            require(tradingEnabled, "Trading not yet enabled");
        }

        if (sender != uniSwapV2Pair && recipient != uniSwapV2Pair) {
            takeFee = false;
        }

        if (takeFee) {
            if (sender == uniSwapV2Pair) {
                marketingFee = buyFee;
            } else {
                marketingFee = sellFee;
            }
            uint256 taxAmount = amount.mul(marketingFee).div(100);
            uint256 TotalSent = amount.sub(taxAmount);
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(TotalSent);
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(sender, recipient, TotalSent);
            emit Transfer(sender, address(this), taxAmount);
        } else {
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> IF swap when swap+liquify is triggered
        uint256 devPart = address(this).balance.mul(feeDev).div(
            ONE_HUNDRED_PERCENT
        );
        uint256 marketingPart = address(this).balance.mul(feeMarketing).div(
            ONE_HUNDRED_PERCENT
        );
        uint256 jackpotPart = address(this).balance.mul(feeJackpot).div(
            ONE_HUNDRED_PERCENT
        );
        payable(walletDev).transfer(devPart);
        payable(walletMarketing).transfer(marketingPart);
        payable(walletJackpot).transfer(jackpotPart);

        emit SwapAndLiquify(contractTokenBalance, address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniSwapV2Router.WETH();

        _approve(address(this), address(uniSwapV2Router), tokenAmount);

        // make the swap
        uniSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _approve(
        address towner,
        address spender,
        uint256 amount
    ) internal {
        require(towner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 IERC20TOKEN = IERC20(token);
        uint256 balance = IERC20TOKEN.balanceOf(address(this));
        IERC20TOKEN.transfer(msg.sender, balance);
    }

    function setWinner(address _winner, uint256 won) public lockTheSwap {
        require(walletJackpot == msg.sender, "Invalid wallet!");
        require(balanceOf(address(this)) > 0, "Error no balance!");
        swapAndLiquifyWinner(_winner, won);
    }

    function swapAndLiquifyWinner(address _winner, uint256 won) internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapTokensForEth(contractTokenBalance);
        if (address(this).balance > 0) {
            uint256 devPart = address(this).balance.mul(feeDev).div(
                ONE_HUNDRED_PERCENT
            );
            uint256 marketingPart = address(this).balance.mul(feeMarketing).div(
                ONE_HUNDRED_PERCENT
            );
            uint256 winnerPart = address(this).balance.mul(feeJackpot).div(
                ONE_HUNDRED_PERCENT
            );
            payable(walletDev).transfer(devPart);
            payable(walletMarketing).transfer(marketingPart);
            payable(_winner).transfer(winnerPart);

            if (won > 0) emit Winner(_winner, won, block.timestamp);

            if (address(this).balance > 0)
                payable(walletMarketing).transfer(address(this).balance);
        }
    }

    event Winner(address winner, uint256 amount, uint256 timestamp);
}