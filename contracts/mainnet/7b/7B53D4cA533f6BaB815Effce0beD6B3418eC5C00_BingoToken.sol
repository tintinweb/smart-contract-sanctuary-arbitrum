/**
 *Submitted for verification at Arbiscan on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * Contract: Bingo Token
 * Trade without a DEX. $BINGO maintains its own internal liquidity.
 */

// Provides a modifier that allows us to prevent callbacks into the contract during execution
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

// Interface to interact with Uniswap style LP
interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// Standard ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint8);
}

// OpenZeppelin style _msgSender() context call
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Ownable handling
contract Ownable is Context {
    address private _owner;

    // Tax wallets
    address public devWallet = 0x2aE8fE8B13478f6543c933fE551C0f6E47CFd23A;
    address public treasuryWallet = 0x6BFfB0dDE29a4827c4E46dB4104b26a0b9e2bb9D;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTeam() {
        require(devWallet == _msgSender() ||
            treasuryWallet == _msgSender(),
            "Ownable: caller is not a team member"); 
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// Primary contract logic
contract BingoToken is IERC20, Context, Ownable, ReentrancyGuard {
    event Buy(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 ETH,
        uint256 dollarBuy
    );
    event Sell(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 ETH,
        uint256 dollarSell
    );
    event FeesMulChanged(uint256 newBuyMul, uint256 newSellMul);
    event StablePairChanged(address newStablePair, address newStableToken);
    event balanceLimitChanged(uint256 newbalanceLimit);

    // Token data
    string private constant _name = "Bingo Token";
    string private constant _symbol = "BINGO";
    uint8 private constant _decimals = 9;
    uint256 private constant _decMultiplier = 10**_decimals;

    // Total supply
    uint256 public constant _totalSupply = 10**8 * _decMultiplier;

    // Balances / Allowances
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    // Fees
    mapping(address => bool) public isFeeExempt;
    uint256 public sellMul = 95; // 5% sell fee
    uint256 public buyMul = 95; // 5% buy fee
    uint256 public constant DIVISOR = 100;

    // Max balance limit
    mapping(address => bool) public isBalanceLimitExempt;
    uint256 public balanceLimit = _totalSupply / 100; // 1% max supply cap per wallet

    // Tax collection
    uint256 public taxBalance = 0; // Current total amount of taxes collected in contract

    // Tax split
    uint256 public devShare = 20; // 20% tax split to dev
    uint256 public treasuryShare = 90; // 80% tax split to treasury
    uint256 public constant SHAREDIVISOR = 100;

    // Known wallets
    address private constant DEAD = address(0xDEAD);

    // Trading parameters
    uint256 public liquidity = 0.777 ether;
    uint256 public liqConst = liquidity * _totalSupply;
    uint256 public constant TRADE_OPEN_TIME = 0;

    // Volume trackers
    mapping(address => uint256) public indVol;
    mapping(uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    // Candlestick data
    uint256 public totalTx;
    mapping(uint256 => uint256) public txTimeStamp;
    struct candleStick {
        uint256 time;
        uint256 open;
        uint256 close;
        uint256 high;
        uint256 low;
    }
    mapping(uint256 => candleStick) public candleStickData;

    // Frontrun guard
    // Works by preventing any address from buying and selling in the same block
    mapping(address => uint256) private _lastBuyBlock;

    // ETH/USDC and USDC pair and token addresses
    address private stablePairAddress; // 0x9A8D82568cbe5CcABbFD7C6a44d00231aA547898
    address private stableAddress; // 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8

    // Initialize supply
    constructor(address _stablePairAddress, address _stableAddress) {
        stablePairAddress = _stablePairAddress;
        stableAddress = _stableAddress;

        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[devWallet] = true;
        isFeeExempt[treasuryWallet] = true;

        isBalanceLimitExempt[msg.sender] = true;
        isBalanceLimitExempt[address(this)] = true;
        isBalanceLimitExempt[DEAD] = true;
        isBalanceLimitExempt[address(0)] = true;
        isBalanceLimitExempt[treasuryWallet] = true;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    // Total token supply
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    // Token balance per address
    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[_account];
    }

    // Allowance per spender for each holder
    function allowance(address _holder, address _spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_holder][_spender];
    }

    // Token name
    function name() public pure returns (string memory) {
        return _name;
    }

    // Token symbol
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    // Token decimals
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // Give token approval for amount to spender
    function approve(address _spender, uint256 _amount)
        public
        override
        returns (bool)
    {
        require(_spender != address(0), "SRG20: approve to the zero address");
        require(
            msg.sender != address(0),
            "SRG20: approve from the zero address"
        );

        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    // Give max approval to spender
    function approveMax(address _spender) external returns (bool) {
        return approve(_spender, type(uint256).max);
    }

    // Retrieve non-burned supply
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD];
    }

    // Management function to change supply per wallet cap
    // Must be at least 1%
    function changeWalletLimit_(uint256 _newLimit) external onlyOwner {
        require(
            _newLimit >= _totalSupply / 100,
            "New wallet limit should be at least 1% of total supply"
        );
        balanceLimit = _newLimit;
        emit balanceLimitChanged(_newLimit);
    }

    // Management function to set address fee exemption
    function changeIsFeeExempt_(address _holder, bool _exempt) external onlyOwner {
        isFeeExempt[_holder] = _exempt;
    }

    // Management function to set address balance cap exemption
    function changeisBalanceLimitExempt_(address _holder, bool _exempt)
        external
        onlyOwner
    {
        isBalanceLimitExempt[_holder] = _exempt;
    }

    /** Transfer Function */
    function transfer(address _recipient, uint256 _amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, _recipient, _amount);
    }

    /** TransferFrom Function */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        address spender = msg.sender;
        //check allowance requirement
        _spendAllowance(_sender, spender, _amount);
        return _transferFrom(_sender, _recipient, _amount);
    }

    /** Internal Transfer */
    function _transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        // make standard checks
        require(
            _recipient != address(0) && _recipient != address(this),
            "ZERO_ADDRESS/SELF_CONTRACT"
        );
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(
            isBalanceLimitExempt[_recipient] ||
                _balances[_recipient] + _amount <= balanceLimit,
            "Max wallet exceeded!"
        );

        // subtract from sender
        _balances[_sender] = _balances[_sender] - _amount;

        // give amount to receiver
        _balances[_recipient] = _balances[_recipient] + _amount;

        // Transfer Event
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }

    // Decrease allowance by amount on all transfers
    function _spendAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        uint256 currentAllowance = _allowances[_owner][_spender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= _amount,
                "SRG20: insufficient allowance"
            );

            unchecked {
                // Decrease allowance
                _approve(_owner, _spender, currentAllowance - _amount);
            }
        }
    }

    // Token approval logic
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    // Purchase BINGO tokens with ETH and deposit them in sender's wallet
    function buy(uint256 _minTokenOut, uint256 _deadline)
        public
        payable
        nonReentrant
        returns (bool)
    {
        // Deadline requirement
        require(_deadline >= block.timestamp, "Deadline expired");

        // Frontrun Guard
        _lastBuyBlock[msg.sender] = block.number;

        // Ensure there is liquidity
        require(liquidity > 0, "The token has no liquidity");

        // Confirm trading is open
        require(block.timestamp >= TRADE_OPEN_TIME, "Trading is not open");

        // Deduct the buy tax
        uint256 postTaxETHAmount = isFeeExempt[msg.sender]
            ? msg.value
            : (msg.value * buyMul) / DIVISOR;

        // Calculate token purchase amount
        uint256 tokensToSend = _balances[address(this)] -
            (liqConst / (postTaxETHAmount + liquidity));

        // Ensure purchase will not make msg.sender's balance exceed max wallet limit
        require(
            _balances[msg.sender] + tokensToSend <= balanceLimit ||
                isBalanceLimitExempt[msg.sender],
            "Max wallet exceeded"
        );

        // Revert if under 1
        require(tokensToSend >= 1, "Must Buy more than 0 decimals of BINGO");

        // Revert for slippage
        require(tokensToSend >= _minTokenOut, "Insufficient output amount");

        // Process token transfers for a buy transaction
        _buy(msg.sender, tokensToSend);

        // Update tax and liquidity balances
        uint256 taxAmount = msg.value - postTaxETHAmount;
        taxBalance += taxAmount;
        liquidity += postTaxETHAmount;

        // Update volume data
        uint256 timestamp = block.timestamp;
        uint256 dollarBuy = msg.value * getETHPriceInUSDC();
        totalVolume += dollarBuy;
        indVol[msg.sender] += dollarBuy;
        tVol[timestamp] += dollarBuy;

        // Update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = timestamp;
        uint256 currentPrice = calculateBINGOPriceInETH() * getETHPriceInUSDC();
        candleStickData[timestamp].time = timestamp;
        if (candleStickData[timestamp].open == 0) {
            if (totalTx == 1) {
                candleStickData[timestamp].open =
                    ((liquidity - postTaxETHAmount) / (_totalSupply)) *
                    getETHPriceInUSDC();
            } else {
                candleStickData[timestamp].open = candleStickData[
                    txTimeStamp[totalTx - 1]
                ].close;
            }
        }
        candleStickData[timestamp].close = currentPrice;

        if (
            candleStickData[timestamp].high < currentPrice ||
            candleStickData[timestamp].high == 0
        ) {
            candleStickData[timestamp].high = currentPrice;
        }

        if (
            candleStickData[timestamp].low > currentPrice ||
            candleStickData[timestamp].low == 0
        ) {
            candleStickData[timestamp].low = currentPrice;
        }

        // Emit Transfer and Buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Buy(
            msg.sender,
            address(this),
            tokensToSend,
            msg.value,
            postTaxETHAmount * getETHPriceInUSDC()
        );
        return true;
    }

    // Process internal balance transfers to and from the contract
    function _buy(address _receiver, uint256 _amount) internal {
        _balances[_receiver] = _balances[_receiver] + _amount;
        _balances[address(this)] = _balances[address(this)] - _amount;
    }

    // Sell BINGO for ETH and automatically send ETH to seller
    function sell(
        uint256 _tokenAmount,
        uint256 _deadline,
        uint256 _minETHOut
    ) public nonReentrant returns (bool) {
        // Deadline requirement
        require(_deadline >= block.timestamp, "Deadline EXPIRED");

        // Frontrun guard
        // Prevents frontrunning by preventing buying and selling in the same block
        require(
            _lastBuyBlock[msg.sender] != block.number,
            "Buying and selling in the same block is not allowed!"
        );

        address seller = msg.sender;

        // Make sure seller's balance is adequate
        require(
            _balances[seller] >= _tokenAmount,
            "cannot sell above token amount"
        );

        // Get how much in ETH the tokens are worth
        uint256 amountETH = liquidity -
            (liqConst / (_balances[address(this)] + _tokenAmount));
        uint256 amountTax = (amountETH * (DIVISOR - sellMul)) / DIVISOR;
        uint256 ethToSend = amountETH - amountTax;

        // Slippage revert
        require(amountETH >= _minETHOut, "Insufficient output amount");

        // Send ETH to Seller
        (bool successful, ) = isFeeExempt[msg.sender]
            ? payable(seller).call{value: amountETH}("")
            : payable(seller).call{value: ethToSend}("");
        require(successful, "ETH transfer failed");

        // Process token transfers for a sell transaction
        _sell(seller, _tokenAmount);

        // Add tax allowance to be withdrawn and remove from liq in the amount of ETH taken by the seller
        taxBalance = isFeeExempt[msg.sender]
            ? taxBalance
            : taxBalance + amountTax;
        liquidity = liquidity - amountETH;

        // Add tokens back into the contract
        _balances[address(this)] = _balances[address(this)] + _tokenAmount;

        // Update volume
        uint256 timestamp = block.timestamp;
        uint256 dollarSell = amountETH * getETHPriceInUSDC();
        totalVolume += dollarSell;
        indVol[msg.sender] += dollarSell;
        tVol[timestamp] += dollarSell;

        // Update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = timestamp;
        uint256 currentPrice = calculateBINGOPriceInETH() * getETHPriceInUSDC();
        candleStickData[timestamp].time = timestamp;
        if (candleStickData[timestamp].open == 0) {
            candleStickData[timestamp].open = candleStickData[
                txTimeStamp[totalTx - 1]
            ].close;
        }
        candleStickData[timestamp].close = currentPrice;

        if (
            candleStickData[timestamp].high < currentPrice ||
            candleStickData[timestamp].high == 0
        ) {
            candleStickData[timestamp].high = currentPrice;
        }

        if (
            candleStickData[timestamp].low > currentPrice ||
            candleStickData[timestamp].low == 0
        ) {
            candleStickData[timestamp].low = currentPrice;
        }

        // Emit Transfer and Sell events
        emit Transfer(seller, address(this), _tokenAmount);
        if (isFeeExempt[msg.sender]) {
            emit Sell(
                address(this),
                msg.sender,
                _tokenAmount,
                amountETH,
                dollarSell
            );
        } else {
            emit Sell(
                address(this),
                msg.sender,
                _tokenAmount,
                ethToSend,
                ethToSend * getETHPriceInUSDC()
            );
        }
        return true;
    }

    // Process internal balance transfers to and from the contract
    function _sell(address _seller, uint256 _amount) internal {
        _balances[_seller] = _balances[_seller] - _amount;
        _balances[address(this)] = _balances[address(this)] + _amount;
    }

    // Returns the total amount of ETH being used in liquidity calculations
    function getLiquidity() public view returns (uint256) {
        return liquidity;
    }

    // Returns the value of a holder's tokens before the sell fee
    function getValueOfHoldings(address _holder) public view returns (uint256) {
        return
            ((_balances[_holder] * liquidity) / _balances[address(this)]) *
            getETHPriceInUSDC();
    }

    // Change fees to a value only between 0-5%
    function changeFees_(uint256 _newBuyMul, uint256 _newSellMul)
        external
        onlyOwner
    {
        require(
            _newBuyMul >= 95 &&
                _newSellMul >= 95 &&
                _newBuyMul <= 100 &&
                _newSellMul <= 100,
            "Fees are out of bounds"
        );

        buyMul = _newBuyMul;
        sellMul = _newSellMul;

        emit FeesMulChanged(_newBuyMul, _newSellMul);
    }

    // Change team and treasury distribution ratio
    function changeTaxDistribution_(
        uint256 _newDevShare,
        uint256 _newTreasuryShare
    ) external onlyOwner {
        require(
            _newDevShare + _newTreasuryShare == SHAREDIVISOR,
            "Sum of shares must be 100"
        );

        devShare = _newDevShare;
        treasuryShare = _newTreasuryShare;
    }

    // Change team and treasury wallet addresses
    function changeFeeReceivers_(
        address _devWallet,
        address _newTreasuryWallet
    ) external onlyOwner {
        require(
            _devWallet != address(0) && 
            _newTreasuryWallet != address(0),
            "New wallets must not be the ZERO address"
        );

        devWallet = _devWallet;
        treasuryWallet = _newTreasuryWallet;
    }

    // Withdraw collected taxes to team and treasury wallets
    function withdrawTaxBalance_() external nonReentrant onlyTeam {
        (bool temp1, ) = payable(devWallet).call{
            value: (taxBalance * devShare) / SHAREDIVISOR
        }("");
        (bool temp2, ) = payable(treasuryWallet).call{
            value: (taxBalance * treasuryShare) / SHAREDIVISOR
        }("");
        assert(temp1 && temp2);
        taxBalance = 0;
    }

    // Return the amount of tokens an amount of ETH can purchase
    function getTokenAmountOut(uint256 _amountETHIn)
        public
        view
        returns (uint256)
    {
        uint256 amountAfter = liqConst / (liquidity - _amountETHIn);
        uint256 amountBefore = liqConst / liquidity;
        return amountAfter - amountBefore;
    }

    // Calculates how much ETH is being returned for the amount of tokens sold
    function getETHAmountOut(uint256 _amountIn) public view returns (uint256) {
        uint256 amountBefore = liqConst / _balances[address(this)];
        uint256 amountAfter = liqConst / (_balances[address(this)] + _amountIn);
        return amountBefore - amountAfter;
    }

    // Add core contract liquidity
    // Liquidity provisioning is not permissionless
    function addLiquidity_() external payable onlyOwner {
        uint256 tokensToAdd = (_balances[address(this)] * msg.value) /
            liquidity;
        require(_balances[msg.sender] >= tokensToAdd, "Not enough tokens!");

        uint256 oldLiq = liquidity;
        liquidity = liquidity + msg.value;
        _balances[address(this)] += tokensToAdd;
        _balances[msg.sender] -= tokensToAdd;
        liqConst = (liqConst * liquidity) / oldLiq;

        emit Transfer(msg.sender, address(this), tokensToAdd);
    }

    // Return market cap in USDC
    function getMarketCapInUSDC() external view returns (uint256) {
        return (getCirculatingSupply() * calculateBINGOPriceInETH() * getETHPriceInUSDC());
    }

    // Management functions to change the ETH/stablecoin pair and stablecoin address values
    function changeStablePair_(address _newStablePair, address _newStableAddress)
        external
        onlyOwner
    {
        require(
            _newStablePair != address(0) && _newStableAddress != address(0),
            "New addresses must not be the ZERO address"
        );

        stablePairAddress = _newStablePair;
        stableAddress = _newStableAddress;
        emit StablePairChanged(_newStablePair, _newStableAddress);
    }

    // Calculate ETH price in USDC by querying Uniswap ETH/USDC pool
    function getETHPriceInUSDC() public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(stablePairAddress);
        IERC20 token1 = pair.token0() == stableAddress
            ? IERC20(pair.token1())
            : IERC20(pair.token0());

        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        if (pair.token0() != stableAddress) {
            (Res1, Res0, ) = pair.getReserves();
        }
        uint256 res0 = Res0 * 10**token1.decimals();
        return (res0 / Res1); // Return amount of token0 needed to buy token1
    }

    // Returns the Current Price of BINGO in ETH
    function calculateBINGOPriceInETH() public view returns (uint256) {
        require(liquidity > 0, "No Liquidity");
        return liquidity / _balances[address(this)];
    }
}