/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract AicheemsToken {
    string public constant name = "Aicheems";
    string public constant symbol = "Aicheems";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000000000000; // 1 trillion ACM
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

   
    address public taxAddress = 0xa773A0e6c5c738b101ae54c1F164A38E3cc379Ba;
    uint256 public constant taxRate = 300; // 3%

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot send tokens to zero address");

        uint256 taxAmount = (_value * taxRate) / 10000;
        uint256 transferAmount = _value - taxAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[taxAddress] += taxAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, taxAddress, taxAmount);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot send tokens to zero address");

        uint256 taxAmount = (_value * taxRate) / 10000;
        uint256 transferAmount = _value - taxAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[taxAddress] += taxAmount;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, taxAddress, taxAmount);

        return true;
    }

    function setTaxAddress(address _newAddress) public {
        require(_newAddress != address(0), "Cannot set tax address to zero address");
        taxAddress = _newAddress;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount, uint256 _deadline) external payable {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Router V2地址
        uint256 minTokenAmount = (_tokenAmount * 997) / 1000; 
        uniswapRouter.addLiquidityETH{ value: msg.value }(
            address(this),
            _tokenAmount,
            minTokenAmount,
            _ethAmount,
            msg.sender,
            _deadline
        );
    }
}