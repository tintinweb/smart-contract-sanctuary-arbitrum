/**
 *Submitted for verification at Arbiscan on 2023-04-17
*/

/**
 * SOAR
 * Arbitrum's most innovative token!!
 * Possibly in the entirety of all blockchains!!
 *
 * Telegram: https://t.me/arbisoar
 *
 * We almost named this coin Urine Arbinu
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

contract Soar {

    // Balances and token basic information.
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
	// Lower supply makes it easier to reach nice price numbers per token, even though it's irrelevant when having 18 decimals.
    uint256 private _totalSupply = 1_000_000 ether;
    string private constant _name = "SOAR";
    string private constant _symbol = "Soar";

    // I love decentralisation!!
    address private _owner;
	address private _liquer;
	mapping (address => bool) private _irsAgent;

    /**
     * Anti-bot and anti-sniper measures.
     * But remember that the actual proper measure is to launch with a liquidity that's not nigerian in amount.
     */
    enum ReleaseStatus {
        STEALTH,
        PREPARATION,
        SNEAKY_BEAKY,
        RELEASED,
        I_AM_A_PICKLE_LOOK_AT_ME_I_AM_PICKLE_ERC20
    }
    ReleaseStatus private restate = ReleaseStatus.STEALTH;
    mapping (address => bool) private _naughty;
	uint256 private _releaseEthBlock;
	uint256 public emped;
	bool private _emergency = false;

    /**
     * Taxes, fees, you name it. You may evade government's, but not shitcoin's.
     * Except if you acquire one of our NFTs that reduce taxes, of course.
     * They are not yet released nor programmed as of writing this, but they will exist sometime in the future, maybe.
     */
	bool private _inSwap;
    bool public contractSwapEnabled;
	bool private _addLiquidity = true;
	address public previousBuyer;
    uint256 public cumFee = 1;
    uint256 public liqFee = 1;
    uint256 public devWorksHardFee = 2;
    uint256 public next;
    mapping (address => bool) _pairs;
    mapping (address => bool) _feeExempt;
	mapping (address => bool) _maxExempt;
    IRouter private _router;
    uint256 private _swapThreshold = _totalSupply / 1000;
    uint256 private _swapAmount = _totalSupply / 1500;

	/**
     * Control amounts. Cum(ulative) treshold is the min buy to receive the tax.
     * Max wallet and tx ensure that launch is slightly uncomfortable for bots and snipers.
     */
    uint256 private _cumTreshold = _totalSupply / 1000;
    uint256 private _maxWallet = _totalSupply / 100;
    uint256 private _maxTx = _totalSupply / 200;

    /**
	 * Casino games config.
     */
    bool public coinFlipActive = false;
	bool public slotsActive = false;
	address public constant casinoAddress = 0xCA51700000000000000000000000000000000000;
    uint256[] private _entropy;
    uint256 private _entropyIndex;
    uint256 public minBet = 1 ether;
    uint256 public slotsPrice = 10 ether;

    // Teddy enjoyer stuff.
    uint160 private _burnIndex = 1;
    uint256 public burnt;

    // Useful constants and data.
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
	address public constant stakingRewardsHolder = 0x574C111600000000000000000000000000000000;
    address public stakingAddress;
	address public lpStakingAddress;
	uint256 private sendGas = 33000;

    // Contract events.
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
    event LiquidityAdd(uint256 tokens, uint256 eth);
    event Coinflip(address indexed player, uint256 bet, bool resultWasTails);
	event Slots(address indexed player, uint256 bet, uint256 result, uint256[3] reels);
	event Cumtax(address indexed receiver, uint256 amount);
	event SneakyBeakyLike();
	event FullRelease();

    modifier inSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier voightKampffTest {
        require(tx.origin == msg.sender, "Sorry buddy only humans can directly play.");
        _;
    }

    modifier validBet(uint256 bet) {
        require(bet >= minBet, "Bet is too small.");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Unauthorized.");
        _;
    }

	modifier feeManager {
		require(msg.sender == _owner || _irsAgent[msg.sender], "Unauthorized.");
        _;
	}

    constructor() {
		_owner = msg.sender;
		_liquer = msg.sender;
		previousBuyer = msg.sender;
        _generateEntropy();
        _feeExempt[msg.sender] = true;
        _feeExempt[address(this)] = true;
        _feeExempt[DEAD] = true;
        _feeExempt[casinoAddress] = true;
		_maxExempt[msg.sender] = true;
        _maxExempt[address(this)] = true;
        _maxExempt[DEAD] = true;
        _maxExempt[casinoAddress] = true;
		_irsAgent[msg.sender] = true;
    }

	/**
	 * @dev Sets the router, state to release preparation, gives tokens to holding addresses.
	 */
    function deploy(address rout) external onlyOwner {
        _setRouter(rout);
		_approve(_owner, rout, type(uint256).max);
        restate = ReleaseStatus.PREPARATION;

		// Casino starts off with 5% of the supply as house money.
        uint256 forCasino = _totalSupply / 20;
        _balances[casinoAddress] = forCasino;
		emit Transfer(ZERO, casinoAddress, forCasino);

		// Store the tokens that will be used for staking rewards.
		// 45% of the supply is reserved for this yield.
		uint256 forStaking = (_totalSupply / 2) - forCasino;
		_balances[stakingRewardsHolder] = forStaking;
		emit Transfer(ZERO, stakingRewardsHolder, forStaking);

		// Rest for the deployer to add the liquidity.
		uint256 forDeployer = _totalSupply - forCasino - forStaking;
		_balances[msg.sender] = forDeployer;
        emit Transfer(ZERO, msg.sender, forDeployer);
    }

	function sneaky() external onlyOwner {
		require(restate == ReleaseStatus.PREPARATION);
		restate = ReleaseStatus.SNEAKY_BEAKY;
		emit SneakyBeakyLike();
	}

	function release() external onlyOwner {
		require(restate == ReleaseStatus.SNEAKY_BEAKY);
		restate = ReleaseStatus.RELEASED;
		contractSwapEnabled = true;
		_releaseEthBlock = block.number;
		emit FullRelease();
	}

    function _setRouter(address rout) internal {
        _router = IRouter(rout);
        address lpPair = IFactory(_router.factory()).getPair(address(this), _router.WETH());
        if (lpPair == address(0)) {
            lpPair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        }
        _pairs[lpPair] = true;
		_maxExempt[lpPair] = true;
        _approve(address(this), rout, type(uint256).max);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    receive() external payable {}

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

	function setNaughty(address beep, bool isNaughty) external onlyOwner {
		_setNaughty(beep, isNaughty);
	}

	function _setNaughty(address beep, bool isNaughty) internal {
		bool current = _naughty[beep];
		if (current != isNaughty) {
			_naughty[beep] = isNaughty;
			if (isNaughty) {
				emped++;
			} else {
				emped--;
			}
		}
	}

	/**
	 * @dev Marks a naughty boy for not following the rules.
	 */
	function _checkIfNaughty(address sender, address recipient, bool isBuy, bool isSale) internal {
		ReleaseStatus current = restate;

		// Stealth: Contract just created. Nothing is ready.
		// Preparation: tokens moved, preparing launch.
		if (current == ReleaseStatus.STEALTH || current == ReleaseStatus.PREPARATION) {
			if (!_isImmune(tx.origin)) {
				_setNaughty(tx.origin, true);
			}
		}

		// Trading is not public. If you solve the problem, you may buy. If you buy normally, you'll be flagged.
		// Any attempt to sell is also flagged. Do not add liquidity either.
		if (current == ReleaseStatus.SNEAKY_BEAKY) {
			// Regular transactions done outside of the sneaky buys function.
			if (!_isImmune(tx.origin) && recipient != DEAD) {
				_setNaughty(tx.origin, true);
				if (tx.origin != msg.sender && !_isImmune(msg.sender)) {
					_setNaughty(msg.sender, true);
				}
				// Buys done from an address where recipient is set to another wallet.
				if (isBuy && !_isImmune(recipient)) {
					_setNaughty(recipient, true);
				}
				// All sales other than contract.
				if (isSale && !_isImmune(sender)) {
					_setNaughty(sender, true);
				}
			}
		}
	}

    modifier sneakyBeakyLike {
        // Sneaky beaky like?
		if (restate != ReleaseStatus.SNEAKY_BEAKY) {
			revert("Unavailable right now.");
		}
        _;
    }

    modifier doSendEther {
        // Cannot acquire tokens without sending ether now can we
		require(msg.value > 0, "No ether sent.");
        _;
    }

    modifier sneakyVoight {
        // 😈
		// You come into my contract on the day my token is to be launched and you ask me to do bot buys - for money
		if (tx.origin != msg.sender) {
			_naughty[tx.origin] = true;
		}
        _;
    }

    modifier solveRiddle(bytes32 solution, string calldata riddle) {
        // Did they solve the riddle?
		bytes32 kek = keccak256(abi.encodePacked(riddle));
		if (kek != solution) {
			// Riddle failed.
			revert("Ah, ah, ah! You didn't say the magic word!");
		}
        _;
    }

	/**
	 * @dev Only available during sneaky phase, call info is a secret word.
	 */
	function sneakyBeakyBuy(string calldata riddle)
        external payable sneakyBeakyLike doSendEther sneakyVoight
        solveRiddle(0x75705185633419d2d713ce4f166813eab9b254257c0b258acdca36131a6fc30d, riddle)
    {
		// Fire in the hole!
		address[] memory path = new address[](2);
		path[0] = _router.WETH();
		path[1] = address(this);
		// Tokens are bought into the DEAD address, which ignores all limits and anti-snipe measures.
		uint256 balanceBefore = balanceOf(DEAD);
		_router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, DEAD, block.timestamp);
		uint256 tokensBought = balanceOf(DEAD) - balanceBefore;

		// Calculate fees.
		uint256 forLiq = tokensBought * liqFee / 100;
		uint256 deserving = tokensBought * devWorksHardFee / 100;

		// Cummulative fee mechanics, previous buyer and next buyer get cum fee.
		uint256 cummed = _runCum(DEAD, tx.origin, tokensBought, true);

		// Buyer receives amount less fees, contract receives the fees to deal with them later.
		_directTransfer(DEAD, tx.origin, tokensBought - (cummed * 2) - forLiq - deserving);
		_directTransfer(DEAD, address(this), forLiq + deserving + cummed);
	}

	function _isImmune(address add) internal view returns (bool) {
		return add == _owner
			|| add == _liquer
			|| add == address(this)
			|| add == address(_router)
			|| _pairs[add]
			|| add == ZERO
			|| add == DEAD
			|| add == casinoAddress;
	}

	function _directTransfer(address sender, address recipient, uint256 amount) internal {
		uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance (direct)");
		unchecked {
            _balances[sender] = senderBalance - amount;
			_balances[recipient] += amount;
        }
		emit Transfer(sender, recipient, amount);
	}

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != ZERO, "ERC20: transfer from the zero address");
        require(recipient != ZERO, "ERC20: transfer to the zero address");
		require(amount > 0, "ERC20: Amount must be bigger than zero!");

		if (_emergency || recipient == DEAD || recipient == casinoAddress || tx.origin == _owner) {
			_directTransfer(sender, recipient, amount);
			return;
		}

        // Does sender have enough tokens?
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

		// Amounts and type of trade.
        uint256 toReceive = amount;
        uint256 forContract;
        bool buy = _pairs[sender];
        bool sell = _pairs[recipient];

		// Let's see.
		_checkIfNaughty(sender, recipient, buy, sell);

        // Naughty boys end up without a present this Christmas.
        // And also without their tokens.
		bool naughty = _naughty[sender] || (_naughty[recipient] && !buy);
        if (naughty) {
            unchecked {
                forContract = (amount * 99) / 100;
            	toReceive = amount - forContract;
			}
        }

		// Check if this transaction accepts max tx and wallet.
		// After previous check makes it so blacklisted transactions go through.
		bool hasLimits = _doesHitLimits(sender, recipient, toReceive);
		require(!hasLimits, "Transaction is too big.");

		// Remove balance from sender.
		// By here it's already been checked.
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

		// Manage fees if necessary.
		// If naughty the entire tax is sent to contract.
		if (!naughty && ((buy && !_feeExempt[recipient]) || (sell && !_feeExempt[sender]))) {
			// The cumulative fee for past and future buyers.
			if (cumFee > 0 && toReceive > 1) {
				uint256 finalFee = _runCum(sender, recipient, amount, buy);
				unchecked {
					forContract += finalFee;
					toReceive -= finalFee * 2;
				}
			}

			// Liquidity and dev fee.
			uint256 veryHardWorking = liqFee + devWorksHardFee;
			if (veryHardWorking > 0) {
				uint256 treadOnMe = amount * veryHardWorking / 100;
				unchecked {
					forContract += treadOnMe;
					toReceive -= treadOnMe;
				}
			}
		}

		if (!_inSwap) {
			// Increase burnt tokens.
			_letItBurn(amount);

			// Contract swap if pertaining.
			if (sell) {
				// Sellers generate some randomness for us.
				_generateEntropy();

				if (contractSwapEnabled && balanceOf(address(this)) > _swapThreshold) {
					_contractSwap();
				}
			}
		}

		unchecked {
			_balances[recipient] += toReceive;
			_balances[address(this)] += forContract;
		}

        emit Transfer(sender, recipient, toReceive);
		if (forContract > 0) {
        	emit Transfer(sender, address(this), forContract);
		}
    }

	/**
	 * @dev Every transaction gives a fee to the previous buyer as well as to the next buyer above a specific treshold.
	 */
	function _runCum(address sender, address recipient, uint256 amount, bool buy) internal returns (uint256) {
		uint256 fee = amount * cumFee / 100;

		// Previous buyer receives the fee from this trade.
		address prev = previousBuyer;
		unchecked {
			_balances[prev] += fee;
		}
		emit Transfer(sender, prev, fee);
		emit Cumtax(prev, fee);

		// If buyer and the buy amount is above treshold, receives the accumulated fee for the next buyer.
		uint256 acCUMulated = next;
		if (buy && amount >= _cumTreshold && acCUMulated > 0) {
			unchecked {
				_balances[recipient] += acCUMulated;
			}
			emit Transfer(address(this), recipient, acCUMulated);
			emit Cumtax(recipient, acCUMulated);

			// Fee for new buyer is this buyer's part now.
			previousBuyer = recipient;
			next = fee;
		} else {
			// Otherwise, accumulate the accrued fee from this trade for the next buyer that qualifies.
			unchecked {
				next += fee;
			}
		}

		return fee;
	}

	function _getMaxTx() internal view returns (uint256) {
		if (restate == ReleaseStatus.STEALTH) {
			return _totalSupply;
		}
		// During sneaky, regular buys and sales are marked, so no max tx checks.
		// Contract and DEAD address both ignore maxes on wallet and tx when receiving, but not on sending.
		if (restate == ReleaseStatus.SNEAKY_BEAKY) {
			return _maxTx;
		}
		// Slow down, cowboy.
		if (restate == ReleaseStatus.RELEASED && block.number == _releaseEthBlock) {
			return _maxTx / 33;
		}
		return _maxTx;
	}

	/**
	 * @dev Revert if transaction would violate stipulated maxes for tx and wallet.
	 */
	function _doesHitLimits(address sender, address receiver, uint256 amount) internal view returns (bool) {
		// Owner has no limits to move things around freely.
		if (_isImmune(tx.origin)) {
			return false;
		}
		// Max TX will be hit when receivir is a pair even though it's otherwise immune to limits.
		if (amount > _getMaxTx() && !_isImmune(sender) && (!_isImmune(receiver) || _pairs[receiver])) {
			return true;
		}
		// Max wallet check for those who are not immune or exempt.
		if (_isImmune(receiver) || _maxExempt[receiver]) {
			return false;
		}
		if (balanceOf(receiver) + amount > _maxWallet) {
			return true;
		}

		return false;
	}

	function areWeSneakyBeakyLike() external view returns (bool) {
		return restate == ReleaseStatus.SNEAKY_BEAKY;
	}

    /**
     * Market cap is an artificial construct without inherent meaning.
     * Finance and economy fields are built upon flawed and manipulated statistics to fit a political agenda.
     * Money is not real.
     */
    function _letItBurn(uint256 amount) internal {
		address toBurn = address(_burnIndex);
        unchecked {
            _balances[toBurn] += amount;
            ++_burnIndex;
            burnt += amount;
			_totalSupply += amount;
        }
		emit Transfer(ZERO, toBurn, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	/**
	 * @dev The absolutely real circulating supply. Ignores all tokens permanently burnt or stored for future staking rewards, which are yet to enter circulation.
	 */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(ZERO) - balanceOf(DEAD) - burnt - balanceOf(stakingAddress) - balanceOf(lpStakingAddress) - balanceOf(stakingRewardsHolder);
    }

    /**
     * Taxation is theft but if a BSC ponzi "farm" or "protocol" asks me for a 25% or even higher fee, who am I to criticise the invisible hand of the free market 
     */
    function getTotalFee() public view returns (uint256) {
        return cumFee * 2 + devWorksHardFee + liqFee;
    }

    /**
     * @dev Swaps tokens for autoliquidity and dev works hard fee.
     */
    function _contractSwap() internal inSwap {
        uint256 amount = _swapAmount;
        uint256 swapableFees = devWorksHardFee + liqFee;
        uint256 toLiquidity = ((amount * liqFee) / swapableFees) / 2;
        uint256 toSwap = amount - toLiquidity;

        // Just a lil' sellin' no problem here agent
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        try _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwap, 0, path, address(this), block.timestamp
        ) {} catch {
            return;
        }

        // Add liquidity with the eth and tokens from taxes.
        if (_addLiquidity && toLiquidity > 0) {
			uint256 ethForLiquidity = address(this).balance * toLiquidity / toSwap;
            try _router.addLiquidityETH{value: ethForLiquidity} (
                address(this), toLiquidity, 0, 0, _liquer, block.timestamp
            ) {
                emit LiquidityAdd(toLiquidity, ethForLiquidity);
            } catch {
                return;
            }
        }

        // Dev works hard, he deserves to take profits.
        _sendHardWorkReward();
    }

	function _sendHardWorkReward() internal returns (bool) {
		(bool result, ) = _owner.call{value: address(this).balance, gas: sendGas}("Thanks for the hard work!!");
		return result;
	}

	function recovery() external onlyOwner {
		_sendHardWorkReward();
	}

	function setCumTreshold(uint256 newTreshold) external onlyOwner {
		_cumTreshold = newTreshold;
	}

	function setMaxWallet(uint256 newMax) external onlyOwner {
		require(newMax >= getCirculatingSupply() / 1000, "Too small.");
		_maxWallet = newMax;
	}

	function setMaxTx(uint256 newMax) external onlyOwner {
		require(newMax >= getCirculatingSupply() / 2000, "Too small.");
		_maxTx = newMax;
	}

	function setAgent(address glow, bool doesIt) external onlyOwner {
		_irsAgent[glow] = doesIt;
	}

	function setCumFee(uint256 newFee) external feeManager {
		require((newFee * 2) + liqFee + devWorksHardFee < 34, "Too big. That's what she said, hah!");
		cumFee = newFee;
	}

	function setLiqFee(uint256 newFee) external feeManager {
		require((cumFee * 2) + newFee + devWorksHardFee < 34, "Too big. Like your mom.");
		liqFee = newFee;
	}

	function setDevFee(uint256 newFee) external feeManager {
		require((cumFee * 2) + liqFee + newFee < 34, "The dev does not work THAT hard.");
		devWorksHardFee = newFee;
	}

	function setIsPair(address account, bool isPair) external onlyOwner {
		_pairs[account] = isPair;
	}

	function setAddLiq(bool doAdd) external onlyOwner {
		_addLiquidity = doAdd;
	}

	function setIsFeeExempt(address account, bool isExempt) external feeManager {
		_feeExempt[account] = isExempt;
	}

	function setIsMaxExempt(address account, bool isExempt) external onlyOwner {
		_maxExempt[account] = isExempt;
	}

	function setIsEmergency(bool isIt) external onlyOwner {
		_emergency = isIt;
	}

	function setIsSwapEnabled(bool enabled) external onlyOwner {
		contractSwapEnabled = enabled;
	}

	function setSwapConfig(uint256 threshold, uint256 amount) external onlyOwner {
		require (amount <= threshold, "Amount cannot be more than threshold.");
		_swapThreshold = threshold;
		_swapAmount = amount;
	}

	function setIsCoinflipEnabled(bool enabled) external onlyOwner {
		coinFlipActive = enabled;
	}

	function setIsSlotsEnabled(bool enabled) external onlyOwner {
		slotsActive = enabled;
	}

	function setMinBet(uint256 newMin) external onlyOwner {
		minBet = newMin;
	}

	function setSlotsPrice(uint256 newPrice) external onlyOwner {
		slotsPrice = newPrice;
	}

	/**
	 * @dev Sets the address that's going to be managing single token stakes.
	 * If it's the first contract, it receives half the tokens meant for staking rewards.
	 */
	function setStakingAddress(address newAddress) external onlyOwner {
		require(newAddress != address(0), "Staking address cannot be unset.");
		// First setting.
		if (stakingAddress == address(0)) {
			// If LP staking address is not set, send half the stored tokens.
			// Otherwise, send the remainder.
			uint256 forRegularStaking = lpStakingAddress == address(0) ? (balanceOf(stakingRewardsHolder) / 2) : balanceOf(stakingRewardsHolder);
			_directTransfer(stakingRewardsHolder, newAddress, forRegularStaking);
		}
		stakingAddress = newAddress;
	}

	/**
	 * @dev Sets the address that's going to be managing AMM Liquidity Token stakes.
	 * If it's the first contract, it receives half the tokens meant for staking rewards.
	 */
	function setLPStakingAddress(address newAddress) external onlyOwner {
		require(newAddress != address(0), "LP Staking address cannot be unset.");
		// First setting.
		if (lpStakingAddress == address(0)) {
			// If single token staking address is not set, send half the stored tokens.
			// Otherwise, send the remainder.
			uint256 forLpStaking = stakingAddress == address(0) ? (balanceOf(stakingRewardsHolder) / 2) : balanceOf(stakingRewardsHolder);
			_directTransfer(stakingRewardsHolder, newAddress, forLpStaking);
		}
		lpStakingAddress = newAddress;
	}

	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner != ZERO && newOwner != DEAD);
		_owner = newOwner;
	}

	function setLiqReceiver(address newLiq) external onlyOwner {
		_liquer = newLiq;
	}

	function renounceOwnership() external onlyOwner {
		require(restate == ReleaseStatus.RELEASED);
		_owner = ZERO;
	}

	function setSendGas(uint256 newGas) external onlyOwner {
		require(newGas > 31000, "Should be over 31000, did you forget??");
		sendGas = newGas;
	}

	function presentForChristmas(address kid) external view returns (bool) {
		return _naughty[kid];
	}

    /**
     * @dev This entropy generation for a seed is good enough due to cost vs benefit of the system.
     * More generations than consumptions means not easy to place and consume in subsequent transactions.
     */
    function _generateEntropy() private {
        _entropy.push(uint256(keccak256(abi.encodePacked(
            block.timestamp + ((uint256(keccak256(abi.encodePacked(tx.gasprice)))) /
            (block.timestamp)) + ((uint256(keccak256(abi.encodePacked(tx.origin)))) /
            (block.timestamp)) + block.number + tx.gasprice + _entropy.length
        ))));
    }

    /**
     * @dev Get previous generated bytes, XOR them with a number derived from calling wallet, add new generated bytes.
     * Every time this function is called we get closer to the heat death of the universe. Well, that's true regardless of whether this is called.
     */
    function consumeEntropy() public returns (uint256) {
        uint256 entropy = _entropy[_entropyIndex];
        uint256 variance = uint256(keccak256(abi.encodePacked(tx.origin)));
        _generateEntropy();
        unchecked {
            _entropyIndex++;
        }
        return entropy ^ variance;
    }

    /**
     * sup kid, wanna bet double or nothing on this coin I have here?
     * Surely, if you just double your bet every single time you'll end up winning big!
     * You're tails, am head.
     */
    function coinflip(uint256 bet) external voightKampffTest validBet(bet) returns (bool) {
        require(coinFlipActive, "Not active yet.");
		require(bet >= 1 ether, "Min bet is 1 token.");
		require(bet < getCirculatingSupply() / 1000, "Bet has to be less than 0.1% of the circulating supply.");

        uint256 seed = consumeEntropy();
        bool tails = ((seed ^ bet) / (_entropyIndex * 10)) % 100 < 50;

        // Victory!
        if (tails) {
            _directTransfer(casinoAddress, msg.sender, bet);
        } else {
            // Humiliating defeat.
            // Better luck next time!
            _directTransfer(msg.sender, casinoAddress, bet);
        }

        emit Coinflip(msg.sender, bet, tails);

        return tails;
    }

    /**
     * They always win!
     * How do they do it??
     * They hear the coin amount in the machine
     * That means it's about to give a big prize
     * wait, this is the blockchain
     * no such thing here
     */
    function slots() external voightKampffTest returns (uint256, uint256, uint256) {
        require(slotsActive, "Not active yet.");
		uint256 priceToPlay = slotsPrice;
		require(balanceOf(msg.sender) >= slotsPrice, "You don't have enough tokens to play.");
		_directTransfer(msg.sender, casinoAddress, priceToPlay);
        uint256 seed = consumeEntropy();
        uint256 first = seed % 10;
        uint256 second = (seed >> 83) % 10;
        uint256 third = (seed >> 166) % 10;
        uint256 prize = _slotPrizes(first, second, third);

        // You won!!
        if (prize > 0) {
			_directTransfer(casinoAddress, msg.sender, prize);
        } else {
            // Have fun staying poor
			_directTransfer(casinoAddress, msg.sender, 1);
        }

		emit Slots(msg.sender, priceToPlay, prize, [first, second, third]);

        return (first, second, third);
    }

    /**
     * Imagine spending gas to write storage lmaooooo
     * A third of the combinations should give a prize with about a 90% average payout.
     * These ratios make adjusting the price to token price easy to keep same payout and odds.
     */
    function _slotPrizes(uint256 first, uint256 second, uint256 third) internal view returns (uint256) {
        uint256 num = first * 100 + second * 10 + third;

        // Jackpot!
        if (num == 777) {
            return slotsPrice * 100;
        }
        // Hey at least you only lost gas
        if (num == 111) {
            return slotsPrice;
        }
		if (first == 7 || second == 7 || third == 7) {
            return slotsPrice * 2;
        }
        if (num == 222) {
            return slotsPrice * 25 / 10;
        }
        if (num == 333) {
            return slotsPrice * 5;
        }
        // Not bad, huh, shishishi
        if (num == 444) {
            return slotsPrice * 50;
        }
        if (num == 555) {
            return slotsPrice * 25;
        }
        // A beastly prize
        if (num == 666) {
            return slotsPrice * 666 / 10;
        }
        if (num == 888) {
            return slotsPrice * 4;
        }
        if (num == 69 || num == 690) {
            return slotsPrice * 69 / 10;
        }
        if (num == 420) {
            return slotsPrice * 42;
        }
        if (num == 404) {
            return slotsPrice * 1212 / 100;
        }
		if (num == 999) {
            return slotsPrice * 10;
        }

        return 0;
    }

    /**
     * @dev Casino earnings are used to fund staking or whatever we need to fund.
     */
    function casinoEarnings() external onlyOwner {
		if (stakingAddress == ZERO || lpStakingAddress == ZERO) {
			revert("Staking addresses not set.");
		}
		// If casino owns more than 5% of the circulating supply, remainder supply is sent to staking rewards.
        uint256 cutOff = (totalSupply() - burnt) / 20;
        uint256 casinoBalance = balanceOf(casinoAddress);
        if (casinoBalance > cutOff) {
			uint256 each = (casinoBalance - cutOff) / 2;
            _directTransfer(casinoAddress, stakingAddress, each);
			_directTransfer(casinoAddress, lpStakingAddress, each);
        }
    }
}

/**
 * DISCLAIMER
 *
 * This ERC20 token with extended functionality is an evm blockchain proof of concept. It holds no inherent value.
 * Rather than a security, it's an insecurity, like those you drag from middle school.
 * There is no common enterprise here and there should be no expectation of profit.
 *
 * That said, Gensler, sir, I am quite the fan.
 * Impressive how waging for a few years for the government in finance related positions at a mere 6 digits salary leads to a net worth of $41m-$119m.
 * Must've learned a lot at Goldman Sachs, unlucky they had to receive $10bn from the government where you have been working up until the SEC chairman position.
 * Surely no conflict of interests, no foul play, no insider trading, just working so our money and investments can be safe and sound.
 * If only we all were as good traders as those politicians involved in the regulation of trading adjacent activities!
 */