// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IAirdrop.sol";
import "./Cloud.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./FManager.sol";

contract NimbusToken is ERC20, Ownable {
    using SafeMath for uint256;

    NimbusCloud public nimbusCloud;
    IUniswapV2Router02 public uniswapV2Router;
    FManager public fManager;
    IAirdrop public airdrop;

    uint256 public launchTime;
    uint256 public maxWallet = 3000 * 1e18;

    bool public isTmpSetActive;
    bool public protectSale;
    bool public isFeeActived;
    bool public isSwapActivated;

    address public nodeManager;

    mapping(address => bool) public whitelists;
    mapping(address => bool) public pairs;

    uint256 public randNonce = 0;
    uint256 public threshold;
    uint256 public nTransfers;

    modifier onlyNodeManager() {
        require(
            nodeManager == _msgSender(),
            "FBD: Caller is not the node manager."
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        NimbusCloud _nimbusCloud,
        address _router,
        address[] memory _managers,
        uint256[] memory _distribution
    ) ERC20(_name, _symbol) {
        require(_distribution.length == 7, "ERR: missing % of total supply");
        require(_managers.length == 5, "ERR: manager address is missing");
        
        isTmpSetActive = true;
        protectSale = true;
        isFeeActived = true;
        isSwapActivated = true;
        
        launchTime = block.timestamp;
        nimbusCloud = _nimbusCloud;

        initLiquidityPair(_router);
        
        whitelists[owner()] = true;

        uint256 lpDistrib = _distribution[0]; // Liquidity Pair: 28% of total supply
        uint256 rpDistrib = _distribution[1]; // Reward Pool: 50% of total supply
        uint256 tDistrib = _distribution[2]; // Treasury: 10% of total supply
        uint256 mDistrib = _distribution[3]; // Marketing: 5% of total supply
        uint256 teamDistrib = _distribution[4]; // Team: 3.5% of total supply
        uint256 bbDistrib = _distribution[5]; // Bug Bounties: 2.5% of total supply
        uint256 airdropDistrib = _distribution[6]; // Airdrop: 1% of total supply

        address ownerManager = _managers[0];        
        address rpManager = _managers[1];
        address mManager = _managers[2];
        address treasuryManager = _managers[3];
        address teamManager = _managers[4];

        _mint(ownerManager, lpDistrib);
        _mint(rpManager, rpDistrib);
        _mint(treasuryManager, tDistrib);
        _mint(teamManager, teamDistrib);
        _mint(mManager, mDistrib.add(bbDistrib).add(airdropDistrib));

        resetThreshold();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !airdrop.isRegister(from) && !airdrop.isRegister(to),
            "ADP: This address has been register."
        );
        require(
            !protectSale || (whitelists[to] && whitelists[from]),
            "ERC20: Sell not open yet."
        );
        require(
            balanceOf(to).add(amount) <= maxWallet || whitelists[to],
            "ERC20: your maximum number of tokens per wallet has been reached"
        );

        require(
            address(fManager) != address(0),
            "ERR: FManager should not be zero address."
        );

        uint256 newAmount = amount;
        uint256 amountToTeam = 0;

        if (isFeeActived &&
            pairs[to] && !whitelists[from]) {
            uint256 sellTax = getDailyTax(from);
            uint256 dailyTax = (1000) - (sellTax);
            newAmount = amount.mul(dailyTax).div(1000);
            amountToTeam = amount.sub(newAmount);
            
            if (nTransfers >= threshold && isSwapActivated) {
                resetThreshold();
                fManager.swap();
            }
            nTransfers ++;
        }

        if (isTmpSetActive && !whitelists[to]) {
            airdrop.addToTmpSet(to);
        }

        if (isFeeActived &&
            pairs[to] && !whitelists[from]) {
            super._transfer(from, address(fManager), amountToTeam);
        }
        super._transfer(from, to, newAmount);
    }

    ///
    /// private actions
    ///

    function randMod(uint256 _modulus) public view returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus + 20;
    }

    function resetThreshold() private {
        randNonce++;
        threshold = randMod(100);
        nTransfers = 0;
    }


    ///
    /// View actions
    ///

    /**
     * Returns the % (1000) of the daily tax
     */
    function getDailyTax(address _receiver) public view returns (uint256) {
        if (nimbusCloud.balanceOf(_receiver) == 0) {
            return 300;
        }
        if (block.timestamp <= (1 days) + (launchTime)) {
            return 120;
        } else if (block.timestamp <= (2 days) + (launchTime)) {
            return 80;
        } else if (block.timestamp <= (3 days) + (launchTime)) {
            return 65;
        }
        return 50;
    }

    ///
    /// Ownable actions
    ///

    /**
     * allow to init/reset liquidy pair config.
     * @param _router address of DEX router
     */
    function initLiquidityPair(address _router) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_router);
        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());
        
        whitelists[address(uniswapV2Pair)] = true;
        whitelists[address(uniswapV2Router)] = true;
        
        pairs[uniswapV2Pair] = true;
    }

    function setPair(address _pair, bool _value) external onlyOwner {
        pairs[_pair] = _value;
        whitelists[_pair] = _value;
    }

    function setProtectSale(bool _value) public onlyOwner {
        protectSale = _value;
    }

    function setWhitelist(address _address, bool _value) external onlyOwner {
        whitelists[_address] = _value;
    }

    function setNodeManager(address _nodeManager) external onlyOwner {
        nodeManager = _nodeManager;
    }

    function setFManager(FManager _fManager) external onlyOwner {
        fManager = _fManager;
        whitelists[address(_fManager)] = true;
    }

    function setTmpSet(bool _value) external onlyOwner {
        isTmpSetActive = _value;
    }
    
    function setAirdrop(address _value) external onlyOwner {
        airdrop = IAirdrop(_value);
    }

    function setLimit(uint256 _mW) external onlyOwner {
        maxWallet = _mW;
    }

    function setFeeActivation(bool _value) external onlyOwner {
        isFeeActived = _value;
    }
}