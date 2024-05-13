// SPDX-License-Identifier: MIT

/**
 * SimpleToken is a simple token contract without cheating
 * This contract contains the minimum functions required for the token to operate.
 * Read Contract: _decimals, decimals, _name, name, _symbol, symbol, allowance, balanceOf, getOwner, totalSupply, owner.
 * Write Contract: transfer, transferFrom, approve, decreaseAllowance, increaseAllowance.
 * Write Contract, only for owner: renounceOwnership, transferOwnership.
 */

pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./AntiBot.sol";
import "./TransferBlock.sol";
import "./LiquidityBlock.sol";
import "./BlackList.sol";
import "./WhiteList.sol";
import "./SwapBlock.sol";

contract SimpleToken is Ownable, IERC20, AntiBot, TransferBlock, 
         BlackList, WhiteList, SwapBlock, LiquidityBlock {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    constructor() {

        _name = "Kvant Token";
        _symbol = "KAT";
        _decimals = 18;
        _totalSupply = 100000000*1000000000000000000;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

    }

    function owner() external view returns (address) {
        return getOwner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address addressOwner, address spender) external view returns (uint256) {
        return _allowances[addressOwner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[sender], "Transfer amount exceeds balance");
        // BlackList
        require(!isBlackListed[msg.sender], "isBlackListed"); 
        // Check TransferPause in TransferBlock
        require(TransferBlock.transferPauseStatus() == false, "Transfer: TransferPause enabled");
        // checkAntiBot
        require(sender == getOwner() || AntiBot.setCheckAntiBot(amount), "AntiBot"); 
        // Check WhiteList
        if(WhiteList.transferOnlyWhitelistStatus() == true){
            // WhiteList
            require(isWhiteListed[msg.sender], "Whitelist enabled. Transfer only for white list."); 
        }

        _balances[sender] = _balances[sender].sub(amount);

        if (addressesIgnoreTax[sender] || addressesIgnoreTax[recipient]) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 amountRecipient = amount;
            uint256 amountTax = 0;

            // checkAddressIgnoreTax

            if (addressesLiquidity[sender] && SwapBlock.getPercentsTaxBuy().length > 0) {

                for (uint i; i < SwapBlock.getPercentsTaxBuy().length; i++) {
                    amountTax = amount.div(100).mul(SwapBlock.getPercentsTaxBuy()[i]);
                    amountRecipient = amountRecipient.sub(amountTax);
                    _balances[SwapBlock.getAddressesTaxBuy()[i]] = SafeMath.add(_balances[SwapBlock.getAddressesTaxBuy()[i]], amountTax);
                    emit Transfer(sender, SwapBlock.getAddressesTaxBuy()[i], amountTax);
                }

                _balances[recipient] = _balances[recipient].add(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);

            } else if (addressesLiquidity[recipient] && SwapBlock.getPercentsTaxSell().length > 0) {

                for (uint i; i < SwapBlock.getPercentsTaxSell().length; i++) {
                    amountTax = amount.div(100).mul(SwapBlock.getPercentsTaxSell()[i]);
                    amountRecipient = amountRecipient.sub(amountTax);
                    _balances[SwapBlock.getAddressesTaxSell()[i]] = SafeMath.add(_balances[SwapBlock.getAddressesTaxSell()[i]], amountTax);
                    emit Transfer(sender, SwapBlock.getAddressesTaxSell()[i], amountTax);
                }

                _balances[recipient] = _balances[recipient].add(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);

            } else if (SwapBlock.getPercentsTaxTransfer().length > 0) {

                for (uint i; i < SwapBlock.getPercentsTaxTransfer().length; i++) {
                    amountTax = amount.div(100).mul(SwapBlock.getPercentsTaxTransfer()[i]);
                    amountRecipient = amountRecipient.sub(amountTax);
                    _balances[SwapBlock.getAddressesTaxTransfer()[i]] = SafeMath.add(_balances[SwapBlock.getAddressesTaxTransfer()[i]], amountTax);
                    emit Transfer(sender, SwapBlock.getAddressesTaxTransfer()[i], amountTax);
                }

                _balances[recipient] = _balances[recipient].add(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);

            } else {
                _balances[recipient] = _balances[recipient].add(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);
            }
        }

    }

    function _approve(address addressOwner, address spender, uint256 amount) internal {
        require(addressOwner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[addressOwner][spender] = amount;
        emit Approval(addressOwner, spender, amount);
    }
        // Mint contract добавление токенов

    function setMint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        setMint(_msgSender(), amount);
        return true;
    }
        // Burn contract сжигание токенов

    function setBurn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public returns (bool) {
        setBurn(_msgSender(), amount);
        return true;
    }
        // Burn BlackList tokens

    function _destroyBlackFunds(address holderAddress) internal {
        require(isBlackListed[holderAddress], "holderAddress is not BlackListed");
        require(_balances[holderAddress] > 0, "holderAddress has no balance");

        uint256 holderBalance = _balances[holderAddress];
        _balances[holderAddress] = 0;
        _totalSupply = _totalSupply.sub(holderBalance);
        emit Transfer(holderAddress, address(0), holderBalance);
    }

    function destroyBlackFunds(address holderAddress) public onlyOwner returns (bool) {
        _destroyBlackFunds(holderAddress);
        return true;
    }

}

// SPDX-License-Identifier: MIT

/**
 * contract SwapBlock
 */

pragma solidity >=0.8.20;

import "./Ownable.sol";
import "./SafeMath.sol";

contract SwapBlock is Ownable {
    using SafeMath for uint256;

    mapping(address=>bool) addressesLiquidity;
    mapping(address=>bool) addressesIgnoreTax;

    uint256[] private percentsTaxBuy;
    uint256[] private percentsTaxSell;
    uint256[] private percentsTaxTransfer;

    address[] private addressesTaxBuy;
    address[] private addressesTaxSell;
    address[] private addressesTaxTransfer;

    function getTaxSum(uint256[] memory _percentsTax) internal pure returns (uint256) {
        uint256 TaxSum = 0;
        for (uint i; i < _percentsTax.length; i++) {
            TaxSum = TaxSum.add(_percentsTax[i]);
        }
        return TaxSum;
    }

    function getPercentsTaxBuy() public view returns (uint256[] memory) {
        return percentsTaxBuy;
    }

    function getPercentsTaxSell() public view returns (uint256[] memory) {
        return percentsTaxSell;
    }

    function getPercentsTaxTransfer() public view returns (uint256[] memory) {
        return percentsTaxTransfer;
    }

    function getAddressesTaxBuy() public view returns (address[] memory) {
        return addressesTaxBuy;
    }

    function getAddressesTaxSell() public view returns (address[] memory) {
        return addressesTaxSell;
    }

    function getAddressesTaxTransfer() public view returns (address[] memory) {
        return addressesTaxTransfer;
    }

    function checkAddressLiquidity(address _addressLiquidity) external view returns (bool) {
        return addressesLiquidity[_addressLiquidity];
    }

    function addAddressLiquidity(address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = true;
    }

    function removeAddressLiquidity (address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = false;
    }

    function checkAddressIgnoreTax(address _addressIgnoreTax) external view returns (bool) {
        return addressesIgnoreTax[_addressIgnoreTax];
    }

    function addAddressIgnoreTax(address _addressIgnoreTax) public onlyOwner {
        addressesIgnoreTax[_addressIgnoreTax] = true;
    }

    function removeAddressIgnoreTax (address _addressIgnoreTax) public onlyOwner {
        addressesIgnoreTax[_addressIgnoreTax] = false;
    }

    function setTaxBuy(uint256[] memory _percentsTaxBuy, address[] memory _addressesTaxBuy) public onlyOwner {
        require(_percentsTaxBuy.length == _addressesTaxBuy.length, "_percentsTaxBuy.length != _addressesTaxBuy.length");

        uint256 TaxSum = getTaxSum(_percentsTaxBuy);
        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit

        percentsTaxBuy = _percentsTaxBuy;
        addressesTaxBuy = _addressesTaxBuy;
    }

    function setTaxSell(uint256[] memory _percentsTaxSell, address[] memory _addressesTaxSell) public onlyOwner {
        require(_percentsTaxSell.length == _addressesTaxSell.length, "_percentsTaxSell.length != _addressesTaxSell.length");

        uint256 TaxSum = getTaxSum(_percentsTaxSell);
        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit

        percentsTaxSell = _percentsTaxSell;
        addressesTaxSell = _addressesTaxSell;
    }

    function setTaxTransfer(uint256[] memory _percentsTaxTransfer, address[] memory _addressesTaxTransfer) public onlyOwner {
        require(_percentsTaxTransfer.length == _addressesTaxTransfer.length, "_percentsTaxTransfer.length != _addressesTaxTransfer.length");

        uint256 TaxSum = getTaxSum(_percentsTaxTransfer);
        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit

        percentsTaxTransfer = _percentsTaxTransfer;
        addressesTaxTransfer = _addressesTaxTransfer;
    }

    function showTaxBuy() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxBuy, addressesTaxBuy);
    }

    function showTaxSell() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxSell, addressesTaxSell);
    }

    function showTaxTransfer() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxTransfer, addressesTaxTransfer);
    }

    function showTaxBuySum() public view returns (uint) {
        return getTaxSum(percentsTaxBuy);
    }

    function showTaxSellSum() public view returns (uint) {
        return getTaxSum(percentsTaxSell);
    }

    function showTaxTransferSum() public view returns (uint) {
        return getTaxSum(percentsTaxTransfer);
    }

}

// SPDX-License-Identifier: MIT

/**
 * contract WhiteList
 */

pragma solidity >=0.8.20;

import "./Ownable.sol";

contract WhiteList is Ownable {

    // mapping WhiteList
    mapping(address=>bool) isWhiteListed;

    // example of adding addresses to the white list
    constructor () {
        isWhiteListed[address(0x1111111111111111111111111111111111111111)] = true;
        isWhiteListed[address(0x2222222222222222222222222222222222222222)] = true;
        isWhiteListed[address(0x3333333333333333333333333333333333333333)] = true;
    }

    function getWhiteListStatus(address _addressUser) external view returns (bool) {
        return isWhiteListed[_addressUser];
    }

    // add address to WhiteList
    function addWhiteList(address _addressUser) public onlyOwner {
        isWhiteListed[_addressUser] = true;
    }

    // add address to WhiteList
    function addWhiteListArray(address[] memory  _addressesUsers) public onlyOwner {
        for (uint i; i < _addressesUsers.length; i++) {
            isWhiteListed[_addressesUsers[i]] = true;
        }
    }

    // remove address to WhiteList
    function removeWhiteList(address _addressUser) public onlyOwner {
        isWhiteListed[_addressUser] = false;
    }

    // Status the TransferOnlyWhitelist
    bool private transferOnlyWhitelist = false;

    // Show status the TransferOnlyWhitelist
    function transferOnlyWhitelistStatus() public view returns (bool) {
        return transferOnlyWhitelist;
    }

    // Activate or deactivate the TransferOnlyWhitelist
    function setTransferOnlyWhitelist(bool _transferOnlyWhitelist) public onlyOwner {
        transferOnlyWhitelist = _transferOnlyWhitelist;
    }

}

// SPDX-License-Identifier: MIT

/**
 * contract BlackList
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";

contract BlackList is Ownable {

    mapping(address=>bool) isBlackListed;

    function getBlackListStatus(address _addressUser) external view returns (bool) {
        return isBlackListed[_addressUser];
    }

    function addBlackList (address _addressUser) public onlyOwner {
        isBlackListed[_addressUser] = true;
    }

    function removeBlackList (address _addressUser) public onlyOwner {
        isBlackListed[_addressUser] = false;
    }

}

// SPDX-License-Identifier: MIT

/**
 * contract LiquidityBlock
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Router01.sol";

contract LiquidityBlock is Ownable {
    using SafeMath for uint256;
    receive() external payable {}
    fallback() external payable {}

    function addFirstLiquidity(address _addressSwapV2Router) public onlyOwner {
        address addressToken = address(this);
        uint256 amountTokens = IERC20(address(this)).balanceOf(address(this));
        uint256 amountETH = address(this).balance;

        require(IERC20(addressToken).approve(_addressSwapV2Router, amountTokens), "approve failed");
        IUniswapV2Router01(_addressSwapV2Router).addLiquidityETH{value: amountETH}(
            addressToken,
            amountTokens,
            amountTokens,
            amountETH,
            msg.sender,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

/**
 * contract TransferBlock
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";

contract TransferBlock is Ownable {

    // Status the TransferPause
    bool private transferPaused = false;

    // Show status the TransferPause
    function transferPauseStatus() public view returns (bool) {
        return transferPaused;
    }

    // Activate or deactivate the TransferPause
    function setTransferPause(bool _transferPaused) public onlyOwner {
        transferPaused = _transferPaused;
    }

}

// SPDX-License-Identifier: MIT

/**
 * contract AntiBot
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";

contract AntiBot is Ownable {

    struct StructAntiBotData {
        bool statusAntiBot;
        uint256 startTime;
        uint256 lastBlockNumber;
        uint256 amountLimit;
        uint256 minBlocksBetweenTransactions;
        uint256 timeDisableAntiBot;
    }

    StructAntiBotData public AntiBotData;

    function setStatusAntiBot(bool _boolStatusAntiBot, uint256 _amountLimit) public onlyOwner {
        AntiBotData.statusAntiBot = _boolStatusAntiBot;
        AntiBotData.startTime = block.timestamp;
        AntiBotData.lastBlockNumber = block.number;
        AntiBotData.amountLimit = _amountLimit;
        AntiBotData.minBlocksBetweenTransactions = 2;
        AntiBotData.timeDisableAntiBot = block.timestamp + 300;
    }

    function setCheckAntiBot(uint256 _amountTransfer) public returns (bool) {
        if(!AntiBotData.statusAntiBot){
            return true;
        }
        if(AntiBotData.timeDisableAntiBot < block.timestamp){
            AntiBotData.statusAntiBot = false;
            return true;
        }
        if(_amountTransfer > AntiBotData.amountLimit){
            return false;
        }
        if((AntiBotData.lastBlockNumber + AntiBotData.minBlocksBetweenTransactions) >= block.number){
            return false;
        }
        AntiBotData.lastBlockNumber = block.number;
        return true;
    }
}

// SPDX-License-Identifier: MIT

/**
 * contract Ownable
 */

pragma solidity >=0.8.0;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyOwner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

/**
 * Library for mathematical operations
 */

pragma solidity >=0.8.0;

// @dev Wrappers over Solidity's arithmetic operations with added overflow * checks.
library SafeMath {
    // Counterpart to Solidity's `+` operator.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    // Counterpart to Solidity's `*` operator.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

/**
 * interface IERC20
 */

pragma solidity >=0.8.0;

interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

// SPDX-License-Identifier: MIT

/**
 * abstract contract Context
 */

pragma solidity >=0.8.0;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

/**
 * contract IUniswapV2Router01
 */

pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external pure returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external pure returns (uint256[] memory amounts);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint deadline) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint256[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint256[] memory amounts);
}