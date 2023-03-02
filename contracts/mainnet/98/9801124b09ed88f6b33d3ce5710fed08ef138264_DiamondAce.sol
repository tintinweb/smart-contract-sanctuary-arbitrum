/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DiamondAce is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    address[] private _excluded;

    string private _name = "Diamond Ace";
    string private _symbol = "ACE";
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 1000000000 * 10**_decimals;

    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingFee = 2;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _stakingFee = 1;
    uint256 private _previousStakingFee = _stakingFee;

    address private marketingFeeReceiver;
    address private stakingFeeReceiver;
    address private liquidityAddress;

    uint256 public _potFee = 2;
    uint256 private _previousPotFee = _potFee;

    uint256 public _potFeeExtra = 6;
    uint256 private _previousPotFeeExtra = _potFeeExtra;

    uint256 public _totalFee = 0;

    // WhitelistMode
    mapping(address => bool) private _isWhitelisted;
    mapping(address => bool) private _hasBoughtOnWhitelist;
    bool public whitelistMode = true;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwap;

    struct GameSettings {
        uint256 maxTxAmount; // maximum number of tokens in one transfer
        uint256 tokenSwapThreshold; // number of tokens needed in contract to swap and sell
        uint256 minimumBuyForPotEligibility; //minimum buy to be eligible to win share of the pot
        uint256 tokensToAddOneSecond; //number of tokens that will add one second to the timer
        uint256 maxTimeLeft; //maximum number of seconds the timer can be
        uint256 potFeeExtraTimeLeftThreshold; //if timer is under this value, the potFeeExtra is used
        uint256 eliglblePlayers; //number of players eligible for winning share of the pot
        uint256 potPayoutPercent; // what percent of the pot is paid out, vs. carried over to next round
        uint256 lastBuyerPayoutPercent; //what percent of the paid-out-pot is paid to absolute last buyer
    }

    GameSettings public gameSettings;

    bool public gameIsActive = false;

    uint256 private roundNumber;

    uint256 private timeLeftAtLastBuy;
    uint256 private lastBuyBlock;
    uint256 private lastBuyTimestamp;

    uint256 private liquidityTokens;
    uint256 private marketingTokens;
    uint256 private stakingTokens;
    uint256 private potTokens;

    address private gameSettingsUpdaterAddress;

    address private presaleContractAddress;

    mapping(uint256 => Buyer[]) buyersByRound;

    modifier onlyGameSettingsUpdater() {
        require(
            _msgSender() == gameSettingsUpdaterAddress,
            "caller != game settings updater"
        );
        _;
    }

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event GameSettingsUpdated(
        uint256 maxTxAmount,
        uint256 tokenSwapThreshold,
        uint256 minimumBuyForPotEligibility,
        uint256 tokensToAddOneSecond,
        uint256 maxTimeLeft,
        uint256 potFeeExtraTimeLeftThreshold,
        uint256 eliglblePlayers,
        uint256 potPayoutPercent,
        uint256 lastBuyerPayoutPercent
    );

    event GameSettingsUpdaterUpdated(
        address oldGameSettingsUpdater,
        address newGameSettingsUpdater
    );

    event RoundStarted(uint256 number, uint256 potValue);

    event Buy(
        bool indexed isEligible,
        address indexed buyer,
        uint256 amount,
        uint256 timeLeftBefore,
        uint256 timeLeftAfter,
        uint256 blockTime,
        uint256 blockNumber
    );

    event RoundPayout(
        uint256 indexed roundNumber,
        address indexed buyer,
        uint256 amount,
        bool success
    );

    event RoundEnded(
        uint256 number,
        address[] winners,
        uint256[] winnerAmountsRound
    );

    enum TransferType {
        Normal,
        Buy,
        Sell,
        RemoveLiquidity
    }

    struct Buyer {
        address buyer;
        uint256 amount;
        uint256 timeLeftBefore;
        uint256 timeLeftAfter;
        uint256 blockTime;
        uint256 blockNumber;
    }

    constructor() {
        gameSettings = GameSettings(
            _totalSupply.div(100), //maxTxAmount is 1 million tokens, 1%
            _totalSupply.div(500), //tokenSwapThreshold is 200000 tokens, 0.2%
            _totalSupply.div(10000), //minimumBuyForPotEligibility is 10000 tokens 0.01%
            _totalSupply.div(100000), //tokensToAddOneSecond is 1000 tokens, 0.001%
            21600, //maxTimeLeft is 6 hours
            600, //potFeeExtraTimeLeftThreshold is 10 minutes
            7, //eliglblePlayers is 7
            70, //potPayoutPercent is 70%
            43 //lastBuyerPayoutPerent is 43% of the 70%, which is ~30% overall
        );

        _isWhitelisted[_msgSender()] = true;

        marketingFeeReceiver = 0x401C177834D3B7D49f56001EBb0e160A18fc1aC3;
        stakingFeeReceiver = 0xF656AA6fD3D25Fc15C563Fe60763a2b355435283;
        
        liquidityAddress = _msgSender();
        gameSettingsUpdaterAddress = _msgSender();

        _totalFee = _liquidityFee.add(_marketingFee).add(_stakingFee).add(
            _potFee
        );

        balances[_msgSender()] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        ); // 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 SushiRouter ARB
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // for any non-zero value it updates the game settings to that value
    function updateGameSettings(
        uint256 maxTxAmount,
        uint256 tokenSwapThreshold,
        uint256 minimumBuyForPotEligibility,
        uint256 tokensToAddOneSecond,
        uint256 maxTimeLeft,
        uint256 potFeeExtraTimeLeftThreshold,
        uint256 eliglblePlayers,
        uint256 potPayoutPercent,
        uint256 lastBuyerPayoutPercent
    ) public onlyGameSettingsUpdater {
        if (maxTxAmount > 0) {
            require(
                maxTxAmount >= 1000000 * 10**9 &&
                    maxTxAmount <= 1000000000 * 10**9
            );
            gameSettings.maxTxAmount = maxTxAmount;
        }
        if (tokenSwapThreshold > 0) {
            require(
                tokenSwapThreshold >= 100000 * 10**9 &&
                    tokenSwapThreshold <= 1000000 * 10**9
            );
            gameSettings.tokenSwapThreshold = tokenSwapThreshold;
        }
        if (minimumBuyForPotEligibility > 0) {
            require(
                minimumBuyForPotEligibility >= 1000 * 10**9 &&
                    minimumBuyForPotEligibility <= 100000 * 10**9
            );
            gameSettings
                .minimumBuyForPotEligibility = minimumBuyForPotEligibility;
        }
        if (tokensToAddOneSecond > 0) {
            require(
                tokensToAddOneSecond >= 100 * 10**9 &&
                    tokensToAddOneSecond <= 10000 * 10**9
            );
            gameSettings.tokensToAddOneSecond = tokensToAddOneSecond;
        }
        if (maxTimeLeft > 0) {
            require(maxTimeLeft >= 7200 && maxTimeLeft <= 86400);
            gameSettings.maxTimeLeft = maxTimeLeft;
        }
        if (potFeeExtraTimeLeftThreshold > 0) {
            require(
                potFeeExtraTimeLeftThreshold >= 60 &&
                    potFeeExtraTimeLeftThreshold <= 3600
            );
            gameSettings
                .potFeeExtraTimeLeftThreshold = potFeeExtraTimeLeftThreshold;
        }
        if (eliglblePlayers > 0) {
            require(eliglblePlayers >= 3 && eliglblePlayers <= 15);
            gameSettings.eliglblePlayers = eliglblePlayers;
        }
        if (potPayoutPercent > 0) {
            require(potPayoutPercent >= 30 && potPayoutPercent <= 99);
            gameSettings.potPayoutPercent = potPayoutPercent;
        }
        if (lastBuyerPayoutPercent > 0) {
            require(
                lastBuyerPayoutPercent >= 10 && lastBuyerPayoutPercent <= 60
            );
            gameSettings.lastBuyerPayoutPercent = lastBuyerPayoutPercent;
        }

        emit GameSettingsUpdated(
            maxTxAmount,
            tokenSwapThreshold,
            minimumBuyForPotEligibility,
            tokensToAddOneSecond,
            maxTimeLeft,
            potFeeExtraTimeLeftThreshold,
            eliglblePlayers,
            potPayoutPercent,
            lastBuyerPayoutPercent
        );
    }

    function renounceGameSettingsUpdater()
        public
        virtual
        onlyGameSettingsUpdater
    {
        emit GameSettingsUpdaterUpdated(gameSettingsUpdaterAddress, address(0));
        gameSettingsUpdaterAddress = address(0);
    }

    function updateGameSettingsUpdater(address newGameSettingsUpdater)
        public
        virtual
        onlyGameSettingsUpdater
    {
        require(
            newGameSettingsUpdater != address(0),
            "ACE: new updater is the zero address"
        );
        emit GameSettingsUpdaterUpdated(
            gameSettingsUpdaterAddress,
            newGameSettingsUpdater
        );
        gameSettingsUpdaterAddress = newGameSettingsUpdater;
    }

    function setPresaleContractAddress(address _address) public onlyOwner {
        require(presaleContractAddress == address(0));
        presaleContractAddress = _address;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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
                "ERC20: transfer amount > allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance < zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        uint256 potFee = currentPotFee();
        uint256 totalFee = _liquidityFee.add(_marketingFee).add(_stakingFee).add(potFee);
        return totalFee;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function changeMarketingWallet(address newWallet) public onlyOwner {
        marketingFeeReceiver = newWallet;
    }

    function changeStakingAddress(address newAddress) public onlyOwner {
        stakingFeeReceiver = newAddress;
    }

    function changeLiquidityAddress(address newAddress) public onlyOwner {
        liquidityAddress = newAddress;
    }

    function setFees(
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 stakingFee,
        uint256 potFee,
        uint256 potFeeExtra
    ) public onlyOwner {
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
        _stakingFee = stakingFee;
        _potFee = potFee;
        _potFeeExtra = potFeeExtra;
        _totalFee = _liquidityFee.add(_marketingFee).add(_stakingFee).add(
            _potFee
        );

        require(_totalFee <= 8 && _totalFee.add(_potFeeExtra) <=12, "Total fee cannot be more than 12%");

    }

    function startGame() public onlyOwner {
        require(!gameIsActive);

        // start on round 1
        roundNumber = roundNumber.add(1);

        timeLeftAtLastBuy = gameSettings.maxTimeLeft;
        lastBuyBlock = block.number;
        lastBuyTimestamp = block.timestamp;

        gameIsActive = true;

        emit RoundStarted(roundNumber, potValue());
    }

    function endWhitelist() public onlyOwner {
        require(whitelistMode);
        whitelistMode = false;
    }

    function setWhitelist(address[] memory addresses, bool[] memory statuses)
        public
        onlyOwner
    {
        require(addresses.length == statuses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            _isWhitelisted[addresses[i]] = statuses[i];
        }
    }

    receive() external payable {}

    function removeAllFee() private {
        if (
            _liquidityFee == 0 &&
            _potFee == 0 &&
            _potFeeExtra == 0 &&
            _stakingFee == 0 &&
            _marketingFee == 0
        ) return;

        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousStakingFee = _stakingFee;
        _previousPotFee = _potFee;
        _previousPotFeeExtra = _potFeeExtra;

        _liquidityFee = 0;
        _marketingFee = 0;
        _stakingFee = 0;
        _potFee = 0;
        _potFeeExtra = 0;

        _totalFee = 0;
    }

    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _stakingFee = _previousStakingFee;
        _potFee = _previousPotFee;
        _potFeeExtra = _previousPotFeeExtra;

        _totalFee = _liquidityFee
            .add(_marketingFee)
            .add(_stakingFee)
            .add(_potFee);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getTransferType(address from, address to)
        private
        view
        returns (TransferType)
    {
        if (from == uniswapV2Pair) {
            if (to == address(uniswapV2Router)) {
                return TransferType.RemoveLiquidity;
            }
            return TransferType.Buy;
        }
        if (to == uniswapV2Pair) {
            return TransferType.Sell;
        }
        if (from == address(uniswapV2Router)) {
            return TransferType.RemoveLiquidity;
        }

        return TransferType.Normal;
    }

    function CheckWhitelist(address to) internal {
        require(_isWhitelisted[to] == true, "You are not whitelisted");
        require(
            _hasBoughtOnWhitelist[to] == false,
            "You have already used your whitelist"
        );
        _hasBoughtOnWhitelist[to] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be > 0");

        TransferType transferType = getTransferType(from, to);

        if (
            gameIsActive &&
            !inSwap &&
            transferType != TransferType.RemoveLiquidity &&
            from != liquidityAddress &&
            to != liquidityAddress &&
            from != presaleContractAddress
        ) {
            require(
                amount <= gameSettings.maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        if (whitelistMode && transferType == TransferType.Buy) {
            CheckWhitelist(to);
        }

        completeRoundWhenNoTimeLeft();

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            gameSettings.tokenSwapThreshold;

        if (
            gameIsActive &&
            overMinTokenBalance &&
            !inSwap &&
            transferType != TransferType.Buy &&
            from != liquidityAddress &&
            to != liquidityAddress
        ) {
            inSwap = true;

            swapBack();

            // If theres anything left, sell and keep as pot rewards
            uint256 sellTokens = balanceOf(address(this));
            if (sellTokens > 0) {
                swapTokensForEth(sellTokens);
            }

            liquidityTokens = 0;
            potTokens = 0;
            marketingTokens = 0;
            stakingTokens = 0;

            inSwap = false;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = gameIsActive;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        if (gameIsActive && transferType == TransferType.Buy) {
            handleBuyer(to, amount);
        }
    }

    function handleBuyer(address buyer, uint256 amount) private {
        int256 oldTimeLeft = timeLeft();

        if (oldTimeLeft < 0) {
            return;
        }

        int256 newTimeLeft = oldTimeLeft +
            int256(amount / gameSettings.tokensToAddOneSecond);

        bool isEligible = buyer != address(uniswapV2Router) &&
            !_isExcludedFromFee[buyer] &&
            amount >= gameSettings.minimumBuyForPotEligibility;

        if (isEligible) {
            Buyer memory newBuyer = Buyer(
                buyer,
                amount,
                uint256(oldTimeLeft),
                uint256(newTimeLeft),
                block.timestamp,
                block.number
            );

            Buyer[] storage buyers = buyersByRound[roundNumber];

            bool added = false;

            // check if buyer would have a 2nd entry in last 7, and remove old one
            for (
                int256 i = int256(buyers.length) - 1;
                i >= 0 &&
                    i >
                    int256(buyers.length) -
                        int256(gameSettings.eliglblePlayers);
                i--
            ) {
                Buyer storage existingBuyer = buyers[uint256(i)];

                if (existingBuyer.buyer == buyer) {
                    // shift all buyers after back one, and put new buyer at end of array
                    for (
                        uint256 j = uint256(i).add(1);
                        j < buyers.length;
                        j = j.add(1)
                    ) {
                        buyers[j.sub(1)] = buyers[j];
                    }

                    buyers[buyers.length.sub(1)] = newBuyer;
                    added = true;

                    break;
                }
            }

            if (!added) {
                buyers.push(newBuyer);
            }
        }

        if (newTimeLeft < 0) {
            newTimeLeft = 0;
        } else if (newTimeLeft > int256(gameSettings.maxTimeLeft)) {
            newTimeLeft = int256(gameSettings.maxTimeLeft);
        }

        timeLeftAtLastBuy = uint256(newTimeLeft);
        lastBuyBlock = block.number;
        lastBuyTimestamp = block.timestamp;

        emit Buy(
            isEligible,
            buyer,
            amount,
            uint256(oldTimeLeft),
            uint256(newTimeLeft),
            block.timestamp,
            block.number
        );
    }

    function swapBack() private {
        uint256 balanceBefore = address(this).balance;
        uint256 tokenAmounts = stakingTokens
            .add(potTokens)
            .add(marketingTokens)
            .add(liquidityTokens.div(2));

        uint256 tokensToLiquidity = balanceOf(address(this)).sub(tokenAmounts);

        swapTokensForEth(tokenAmounts);

        uint256 amountETH = address(this).balance - balanceBefore;

        uint256 amountForMarketing = amountETH.mul(marketingTokens).div(tokenAmounts);
        uint256 amountForStaking = amountETH.mul(stakingTokens).div(tokenAmounts);
        uint256 amountForLiquidity = amountETH.mul(liquidityTokens).div(tokenAmounts);

        (bool tmpSuccess1, ) = payable(marketingFeeReceiver).call{
            value: amountForMarketing,
            gas: 30000
        }("");

        (tmpSuccess1, ) = payable(stakingFeeReceiver).call{
            value: amountForStaking,
            gas: 30000
        }("");

        addLiquidity(tokensToLiquidity, amountForLiquidity);

        emit SwapAndLiquify(tokensToLiquidity, amountETH, amountForLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        _transferStandard(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 totalAmount
    ) private {
        (
            uint256 liquidityAmount,
            uint256 marketingAmount,
            uint256 stakingAmount,
            uint256 potAmount,
            uint256 remainingAmount
        ) = _getFeeAmounts(totalAmount);

        balances[sender] = balances[sender].sub(totalAmount);
        balances[recipient] = balances[recipient].add(remainingAmount);

        _takeFees(liquidityAmount, marketingAmount, stakingAmount, potAmount);

        emit Transfer(sender, recipient, totalAmount);
    }

    function _getFeeAmounts(uint256 totalTransferAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 liquidity = totalTransferAmount.mul(_liquidityFee).div(100);
        uint256 marketing = totalTransferAmount.mul(_marketingFee).div(100);
        uint256 staking = totalTransferAmount.mul(_stakingFee).div(100);
        uint256 pot = totalTransferAmount.mul(currentPotFee()).div(100);

        uint256 totalFeeTokens = liquidity.add(marketing).add(staking).add(pot);

        uint256 remainingAmount = totalTransferAmount.sub(totalFeeTokens);

        return (liquidity, marketing, staking, pot, remainingAmount);
    }

    function _takeFees(
        uint256 liquidity,
        uint256 marketing,
        uint256 staking,
        uint256 pot
    ) private {
        uint256 totalFeeTokens = liquidity.add(marketing).add(staking).add(pot);

        balances[address(this)] = balances[address(this)].add(totalFeeTokens);

        uint256 potFee = currentPotFee();
        uint256 totalFee = _liquidityFee.add(_marketingFee).add(_stakingFee).add(potFee);

        if (totalFeeTokens > 0 && totalFee > 0) {
            potTokens = potTokens.add(
                totalFeeTokens.mul(potFee).div(totalFee)
            );
            liquidityTokens = liquidityTokens.add(
                totalFeeTokens.mul(_liquidityFee).div(totalFee)
            );
            marketingTokens = marketingTokens.add(
                totalFeeTokens.mul(_marketingFee).div(totalFee)
            );
            stakingTokens = stakingTokens.add(
                totalFeeTokens.mul(_stakingFee).div(totalFee)
            );
        }
    }

    function potValue() public view returns (uint256) {
        return
            address(this).balance.mul(gameSettings.potPayoutPercent).div(100);
    }

    function timeLeft() public view returns (int256) {
        if (!gameIsActive) {
            return 0;
        }

        // uint256 blocksSinceLastBuy = block.number.sub(lastBuyBlock);

        uint256 timeSinceLastBuy = block.timestamp.sub(lastBuyTimestamp);

        return int256(timeLeftAtLastBuy) - int256(timeSinceLastBuy);
    }

    function currentPotFee() public view returns (uint256) {
        if (timeLeft() < int256(gameSettings.potFeeExtraTimeLeftThreshold)) {
            return _potFeeExtra;
        }
        return _potFee;
    }

    function completeRoundWhenNoTimeLeft() public {
        int256 secondsLeft = timeLeft();

        if (secondsLeft >= 0) {
            return;
        }

        (
            address[] memory buyers,
            uint256[] memory payoutAmounts
        ) = _getPayoutAmounts();

        uint256 lastRoundNumber = roundNumber;

        roundNumber = roundNumber.add(1);

        timeLeftAtLastBuy = gameSettings.maxTimeLeft;
        lastBuyBlock = block.number;
        lastBuyTimestamp = block.timestamp;

        for (uint256 i = 0; i < buyers.length; i = i.add(1)) {
            uint256 amount = payoutAmounts[i];

            if (amount > 0) {
                (bool success, ) = buyers[i].call{value: amount, gas: 5000}("");

                emit RoundPayout(lastRoundNumber, buyers[i], amount, success);
            }
        }

        emit RoundEnded(lastRoundNumber, buyers, payoutAmounts);

        emit RoundStarted(roundNumber, potValue());
    }

    function _getPayoutAmounts()
        internal
        view
        returns (address[] memory buyers, uint256[] memory payoutAmounts)
    {
        buyers = new address[](gameSettings.eliglblePlayers);
        payoutAmounts = new uint256[](gameSettings.eliglblePlayers);

        Buyer[] storage roundBuyers = buyersByRound[roundNumber];

        if (roundBuyers.length > 0) {
            uint256 totalPayout = potValue();

            uint256 lastBuyerPayout = totalPayout
                .mul(gameSettings.lastBuyerPayoutPercent)
                .div(100);

            uint256 payoutLeft = totalPayout.sub(lastBuyerPayout);

            uint256 numberOfWinners = roundBuyers.length >
                gameSettings.eliglblePlayers
                ? gameSettings.eliglblePlayers
                : roundBuyers.length;

            uint256 amountLeft;

            for (
                int256 i = int256(roundBuyers.length) - 1;
                i >= int256(roundBuyers.length) - int256(numberOfWinners);
                i--
            ) {
                amountLeft = amountLeft.add(roundBuyers[uint256(i)].amount);
            }

            uint256 returnIndex = 0;

            for (
                int256 i = int256(roundBuyers.length) - 1;
                i >= int256(roundBuyers.length) - int256(numberOfWinners);
                i--
            ) {
                uint256 amount = roundBuyers[uint256(i)].amount;

                uint256 payout = 0;

                if (amountLeft > 0) {
                    payout = payoutLeft.mul(amount).div(amountLeft);
                }

                amountLeft = amountLeft.sub(amount);
                payoutLeft = payoutLeft.sub(payout);

                buyers[returnIndex] = roundBuyers[uint256(i)].buyer;
                payoutAmounts[returnIndex] = payout;

                if (returnIndex == 0) {
                    payoutAmounts[0] = payoutAmounts[0].add(lastBuyerPayout);
                }

                returnIndex = returnIndex.add(1);
            }
        }
    }

    function gameStats()
        external
        view
        returns (
            uint256 currentRoundNumber,
            int256 currentTimeLeft,
            uint256 currentPotValue,
            uint256 currentTimeLeftAtLastBuy,
            uint256 currentLastBuyBlock,
            uint256 currentBlockTime,
            uint256 currentBlockNumber,
            address[] memory lastBuyerAddress,
            uint256[] memory lastBuyerData
        )
    {
        currentRoundNumber = roundNumber;
        currentTimeLeft = timeLeft();
        currentPotValue = potValue();
        currentTimeLeftAtLastBuy = timeLeftAtLastBuy;
        currentLastBuyBlock = lastBuyBlock;
        currentBlockTime = block.timestamp;
        currentBlockNumber = block.number;

        lastBuyerAddress = new address[](gameSettings.eliglblePlayers);
        lastBuyerData = new uint256[](gameSettings.eliglblePlayers.mul(6));

        Buyer[] storage buyers = buyersByRound[roundNumber];

        uint256 iteration = 0;

        (, uint256[] memory payoutAmounts) = _getPayoutAmounts();

        for (int256 i = int256(buyers.length) - 1; i >= 0; i--) {
            Buyer storage buyer = buyers[uint256(i)];

            lastBuyerAddress[iteration] = buyer.buyer;
            lastBuyerData[iteration.mul(6).add(0)] = buyer.amount;
            lastBuyerData[iteration.mul(6).add(1)] = buyer.timeLeftBefore;
            lastBuyerData[iteration.mul(6).add(2)] = buyer.timeLeftAfter;
            lastBuyerData[iteration.mul(6).add(3)] = buyer.blockTime;
            lastBuyerData[iteration.mul(6).add(4)] = buyer.blockNumber;
            lastBuyerData[iteration.mul(6).add(5)] = payoutAmounts[iteration];

            iteration = iteration.add(1);

            if (iteration == gameSettings.eliglblePlayers) {
                break;
            }
        }
    }
}