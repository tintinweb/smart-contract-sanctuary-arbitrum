// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ICamelotFactory.sol";
import "./ICamelotRouter.sol";
import "./IWETH.sol";

contract Foundation is ERC20, Ownable {
    uint256 private _decimals = 18;
    string private _name = "Founds";
    string private _symbol = "FUD";
    address public pair;
    bool private initialized;
    mapping(address => bool) public blacklists;

    ICamelotFactory private immutable factory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
    ICamelotRouter private immutable swapRouter = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    IWETH private immutable WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    uint256 private immutable _totalSupply = 1000000 * 10 ** _decimals;
    uint256 public _maxHoldingAmount = 0 * 10 ** _decimals;
    uint256 public _minHoldingAmount = 0 * 10 ** _decimals;


    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Token is already initialized");
        pair = factory.createPair(address(WETH), address(this));
        initialized = true;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(uint256 max_holding_amount, uint256 min_holding_amount) external onlyOwner {
        _maxHoldingAmount = max_holding_amount;
        _minHoldingAmount = min_holding_amount;
    }


    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return _bTokenTransfer(_msgSender(), to, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _bTokenTransfer(sender, recipient, amount);
    }

    function _bTokenTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!blacklists[sender] && !blacklists[recipient], "Address is blacklisted");

        if (pair == address(0)) {
            require(sender == owner() || recipient == owner(), "Trading is not started");
            return true;
        }

        if (_maxHoldingAmount > 0){
            require(super.balanceOf(recipient) + amount <= _maxHoldingAmount && super.balanceOf(recipient) + amount >= _minHoldingAmount, "Limited holding amount");
        }
        
        _transfer(sender, recipient, amount);

        return true;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}