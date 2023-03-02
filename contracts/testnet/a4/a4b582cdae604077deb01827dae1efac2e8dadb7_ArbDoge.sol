// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract ArbDoge is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 constant MAX_TOTAL_SUPPLY = 10000000000 * 10 ** 9;
    uint256 constant MAX_TOKENS_FOR_REWARDS = 2000000000 * 10 ** 9;
    uint256 constant MAX_TOKENS_FOR_MARKETING = 3000000000 * 10 ** 9;
    uint256 constant MAX_TOKENS_FOR_STAKING = 3000000000 * 10 ** 9;

    mapping(address => bool) botAddresses;
    mapping(address => uint256) private stakingWhitelist;
    mapping(address => bool) blackList;
    mapping(address => bool) private transferWhitelist;

    IUniswapV2Router02 public uniswapV2Router;

    address private uniswapV2Pair;
    address private stakingWallet;
    address private manager;

    uint256 public tokensForMarketing = MAX_TOKENS_FOR_MARKETING;
    uint256 public tokensForRewards = MAX_TOKENS_FOR_REWARDS;
    uint256 public tokensForStaking = MAX_TOKENS_FOR_STAKING;

    // Anti bot-trade
    bool private antiBotEnabled;
    uint256 private antiBotDuration = 15 minutes;
    uint256 private antiBotTime;
    uint256 private antiBotAmount;

    // Transfer fee & burn
    uint256 private sellFeeRate = 4;
    uint256 private burnFeeRate = 2;
    address internal constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    modifier onlySupporter() {
        require(
            msg.sender == manager || msg.sender == owner() || msg.sender == stakingWallet,
            "Caller is not supporter"
        );
        _;
    }

    event Burn(address indexed from, uint256 burnAmount);
    event HavestStaking(address indexed wallet, uint256 claimAmount);

    constructor() ERC20("Arbdoge", "ARBDOG") {
        stakingWallet = msg.sender;
        _mint(msg.sender, MAX_TOTAL_SUPPLY.sub(tokensForStaking).sub(tokensForRewards));
        _mint(address(this), tokensForStaking.add(tokensForRewards));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x81cD91B6BD7D275a7AeebBA15929AE0f0751d18C //arbitrum testnet
        );
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Pair = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _approve(msg.sender, address(uniswapV2Router), type(uint256).max);
        transferWhitelist[msg.sender] = true;
    }

    /**
     * Set an address of the management contract.
     */
    function setManager(address _manager) public onlyOwner {
        require(!blackList[_manager], "Address is blocked by owner");
        manager = _manager;
    }

    function setTokensForMarketing(uint256 _tokensForMarketing) public onlySupporter {
        require(_tokensForMarketing < MAX_TOKENS_FOR_MARKETING);
        tokensForMarketing = _tokensForMarketing;
    }

    function setTokensForRewards(uint256 _tokensForRewards) public onlySupporter {
        require(_tokensForRewards < MAX_TOKENS_FOR_REWARDS);
        tokensForRewards = _tokensForRewards;
    }

    function settokensForStaking(uint256 _tokensForStaking) public onlySupporter {
        require(_tokensForStaking < MAX_TOKENS_FOR_STAKING);
        tokensForStaking = _tokensForStaking;
    }

    function addStakingWhitelist(
        address[] memory to,
        uint256[] memory amount
    ) public onlySupporter {
        require(to.length == amount.length, "Invalid arguments");
        for (uint256 index = 0; index < to.length; index++) {
            if (blackList[to[index]]) {
                revert("Address is blocked by owner");
            }
            stakingWhitelist[to[index]] = amount[index];
        }
    }

    /**
     * Allows users to claim tokens from an staking.
     */
    function havestStaking() public {
        require(
            stakingWhitelist[msg.sender] > 0,
            "It's not possible to claim an staking at this address."
        );
        require(
            tokensForStaking > 0,
            "The amount of tokens available for the staking has been exhausted."
        );
        uint256 claimAmount = stakingWhitelist[msg.sender];
        require(claimAmount <= balanceOf(address(this)), "No enough balance to pay.");

        stakingWhitelist[msg.sender] = 0;
        _transfer(address(this), msg.sender, claimAmount);
        tokensForStaking = tokensForStaking.sub(claimAmount);
        emit HavestStaking(msg.sender, claimAmount);
    }

    function setBotAddresses(address[] memory _addresses) external onlySupporter {
        require(_addresses.length > 0);
        for (uint256 index = 0; index < _addresses.length; index++) {
            address botAddress = address(_addresses[index]);
            if (blackList[botAddress]) {
                revert("Address is blocked by owner");
            }
            if (owner() == botAddress || stakingWallet == botAddress || manager == botAddress) {
                revert("Cannot block");
            }
            botAddresses[address(_addresses[index])] = true;
        }
    }

    function addBotAddress(address _address) external onlySupporter {
        require(!botAddresses[_address]);
        require(!blackList[_address], "Address is blocked by owner");
        botAddresses[_address] = true;
    }

    /**
     * To prevent bot trading, limit the number of tokens that can be transferred.
     */
    function antiBot(uint256 amount) external onlySupporter {
        require(amount > 0, "Not accept 0 value");
        require(!antiBotEnabled);
        antiBotAmount = amount;
        antiBotTime = block.timestamp + antiBotDuration;
        antiBotEnabled = true;
    }

    function sweepTokenForMarketing(uint256 amount) public onlySupporter {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (tokensForMarketing >= amount && amount < contractTokenBalance) {
            swapTokensForEth(amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        require(stakingWallet != address(0), "Invalid marketing address");
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            stakingWallet, // The contract
            block.timestamp
        );
        tokensForMarketing = tokensForMarketing.sub(tokenAmount);
    }

    /**
     * After the user has won the game, send them a reward.
     */
    function rewards(address recipient, uint256 amount) external onlySupporter {
        require(recipient != address(0), "0x is not accepted here");
        require(tokensForRewards > 0, "Rewards not available");
        require(amount > 0, "Not accept 0 value");
        require(!blackList[recipient], "Address is blocked by owner");
        if (tokensForRewards >= amount) {
            _mint(recipient, amount);
            tokensForRewards = tokensForRewards.sub(amount);
        } else {
            _mint(recipient, tokensForRewards);
            tokensForRewards = 0;
        }
    }

    function setStakingWallet(address _address) external onlySupporter {
        require(_address != address(0), "0x is not accepted here");
        require(!blackList[_address], "Address is blocked by owner");
        stakingWallet = _address;
    }

    /**
     * Add a bot prevention feature by overriding the _transfer function.
     * Take the transfer Fee in Sell direction
     * Or take the normal transfer fee, except whitelist addresses
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!blackList[sender], "Sender address is blocked by owner");
        require(!blackList[recipient], "Recipient address is blocked by owner");
        if (antiBotTime > block.timestamp && amount > antiBotAmount && botAddresses[sender]) {
            revert("Anti Bot");
        }
        require(amount <= balanceOf(sender), "Insufficient funds");
        uint256 feeRate = (recipient == uniswapV2Pair) ? sellFeeRate : 0;
        if (feeRate > 0 && transferWhitelist[sender] == false) {
            uint256 totalFeeAmount = (amount * feeRate) / 100;
            uint256 burnAmount = (amount * burnFeeRate) / 100;
            //burn
            super._transfer(sender, burnAddress, burnAmount);
            emit Burn(sender, burnAmount);
            //for staking
            super._transfer(sender, stakingWallet, totalFeeAmount - burnAmount);
            //remaining for recipient
            super._transfer(sender, recipient, amount - totalFeeAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * Allow address
     */
    function allowAddress(address _address) external onlySupporter {
        blackList[_address] = false;
    }

    /**
     * Block address
     */
    function blockAddress(address _address) external onlySupporter {
        blackList[_address] = true;
    }

    /**
     * Set sell fee rate
     */
    function setSellFeeRate(uint256 fee) external onlySupporter {
        sellFeeRate = fee;
    }

    /**
     * Set antibot time
     */
    function setAntiBotDuration(uint256 time) external onlySupporter {
        antiBotDuration = time;
    }

    /**
     * remove whitelist
     */
    function removeWhiteList(address _whitelist) public onlySupporter {
        transferWhitelist[_whitelist] = false;
    }

    /**
     * add whitelist
     */
    function setWhiteList(address _whitelist) public onlySupporter {
        transferWhitelist[_whitelist] = true;
    }

    /**
     * set burn fee, but must be lower sellFeeRate
     */
    function setBurnFeeRate(uint256 _burnRate) public onlySupporter {
        require(_burnRate > 0 && _burnRate <= sellFeeRate, "Invalid burn fee rate");
        burnFeeRate = _burnRate;
    }

    // receive eth from uniswap swap
    receive() external payable {}
}