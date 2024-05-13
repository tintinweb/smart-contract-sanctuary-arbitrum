// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

/**
 * LPTools is a contract for adding and finding liquidity v2
 * The createLiquidityPool method allows you to add the first liquidity v2 for tokens and save the input data
 * The getLiquidityPoolAllData and getTokenAllDataByPair methods allow you to get the initial pool creation data
 * The getLPTokensData method allows you to find liquidity v2 in DEX
 */

 /**
 * Important! Always check LP, LPLock, Tokenomics. Do Your Own Research.
 * Important! You can use the contract in DAppCrypto https://dappcrypto.github.io/
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./Wallet.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./TaxCreationBlock.sol";
import "./SafeMath.sol";

contract LPTools is Ownable, Wallet, TaxCreationBlock {
    using SafeMath for uint256;

    event NewLiquidityPool(address indexed newContractTokenAddress, uint256 indexed numberPool);

    uint256 public version=1;
    uint256 public amountPools = 0;

    function getVersion() public view returns (uint256) {
        return version;
    }

    // mappingPoolsContracts[addressPair] = numberPool
    mapping(address => uint256) public mappingPoolsContracts;

    struct PoolData {
        uint256 numberPool;
        address addressOwner;
        address addressSender;
        address addressRouter;
        address token0;
        address token1;
        uint256 amountToken0;
        uint256 amountToken1;
        uint256 amountLiquidity;
        address addressPair;
        uint256 timeCreation;
    }
    // mappingPoolsData[numberPool] = PoolData
    mapping(uint256 => PoolData) public mappingPoolsData;

    function createLiquidityPool(address _addressRouter, address _token0, uint256 _amountToken0, address _token1, uint256 _amountToken1, address _addressOwner) payable public {
        sendTaxCreation();
        if(_token1 == address(0)){
            require(msg.value >= (_amountToken1).add(taxCreation), "You must send eth");
        }

        address addressToken1 = _token1;
        if(_token1 == address(0)){
            addressToken1 = IUniswapV2Router(_addressRouter).WETH();
        }

        address addressFactory = IUniswapV2Router(_addressRouter).factory();
        address addressPair = IUniswapV2Factory(addressFactory).getPair(_token0, addressToken1);
        require(addressPair == address(0), "LP already exists");
        require(mappingPoolsContracts[addressPair] == 0, "Pool already exists");

        amountPools++;

        require(IERC20(_token0).transferFrom(msg.sender, address(this), _amountToken0), "TransferFrom failed. Approval required.");
        require(IERC20(_token0).approve(_addressRouter, _amountToken0), "approve failed");
        uint256 amountToken0 = 0;
        uint256 amountToken1 = 0;
        uint256 amountLiquidity = 0;
        if(_token1 == address(0)){
            (amountToken0, amountToken1, amountLiquidity) = IUniswapV2Router(_addressRouter).addLiquidityETH{value: _amountToken1}(
            _token0,
            _amountToken0,
            _amountToken0,
            _amountToken1,
            _addressOwner,
            block.timestamp
            );
        } else {
            (amountToken0, amountToken1, amountLiquidity) = IUniswapV2Router(_addressRouter).addLiquidity(
            _token0,
            _token1,
            _amountToken0,
            _amountToken1,
            _amountToken0,
            _amountToken1,
            _addressOwner,
            block.timestamp
            );
        }

        addressFactory = IUniswapV2Router(_addressRouter).factory();
        addressPair = IUniswapV2Factory(addressFactory).getPair(_token0, addressToken1);

        mappingPoolsContracts[addressPair] = amountPools;

        mappingPoolsData[amountPools].numberPool = amountPools;
        mappingPoolsData[amountPools].addressPair = addressPair;
        
        mappingPoolsData[amountPools].addressOwner = _addressOwner;
        mappingPoolsData[amountPools].addressSender = msg.sender;
        mappingPoolsData[amountPools].addressRouter = _addressRouter;
        mappingPoolsData[amountPools].token0 = _token0;
        mappingPoolsData[amountPools].token1 = addressToken1;
        mappingPoolsData[amountPools].amountToken0 = amountToken0;
        mappingPoolsData[amountPools].amountToken1 = amountToken1;
        mappingPoolsData[amountPools].amountLiquidity = amountLiquidity;
        mappingPoolsData[amountPools].timeCreation = block.timestamp;

        emit NewLiquidityPool(addressPair, amountPools);
    }

    function getLiquidityPoolAllData(uint256 _numberPool, address _addressAccount, address _addressSpender) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256[] memory uintArr = new uint256[](50);
        address[] memory addressArr = new address[](50);
        bool[] memory boolArr = new bool[](50);
        string[] memory stringArr = new string[](50);

        if(mappingPoolsData[_numberPool].numberPool==0){
            return (uintArr, addressArr, boolArr, stringArr);
        }

        // uintArr
        uintArr[0] = mappingPoolsData[_numberPool].numberPool;
        uintArr[1] = mappingPoolsData[_numberPool].amountToken0;
        uintArr[2] = mappingPoolsData[_numberPool].amountToken1;
        uintArr[3] = mappingPoolsData[_numberPool].amountLiquidity;
        uintArr[4] = mappingPoolsData[_numberPool].timeCreation;
        uintArr[10] = version;

        // addressArr
        addressArr[0] = mappingPoolsData[_numberPool].addressOwner;
        addressArr[1] = mappingPoolsData[_numberPool].addressRouter;
        addressArr[2] = mappingPoolsData[_numberPool].token0;
        addressArr[3] = mappingPoolsData[_numberPool].token1;
        addressArr[4] = mappingPoolsData[_numberPool].addressPair;
        addressArr[5] = mappingPoolsData[_numberPool].addressSender;
        addressArr[6] = _addressAccount;
        addressArr[7] = _addressSpender;

        return (uintArr, addressArr, boolArr, stringArr);
    }

    function getTokenAllDataByPair(address _addressPair, address _addressOwner, address _addressSpender) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256 _numberPool = mappingPoolsContracts[_addressPair];
        return getLiquidityPoolAllData(_numberPool, _addressOwner, _addressSpender);
    }

    function getLPTokensData(address _addressRouter, address _token0, address _token1) public view returns (uint256[] memory, address[] memory, string[] memory) {
        uint256[] memory uintArr = new uint256[](50);
        address[] memory addressArr = new address[](50);
        string[] memory stringArr = new string[](50);

        address addressWETH = IUniswapV2Router(_addressRouter).WETH();
        if(_token0==address(0)){ _token0 = addressWETH; }
        if(_token1==address(0)){ _token1 = addressWETH; }

        address addressFactory = IUniswapV2Router(_addressRouter).factory();
        address addressPair = IUniswapV2Factory(addressFactory).getPair(_token0, _token1);

        addressArr[0] = _addressRouter;
        addressArr[1] = addressWETH;
        addressArr[2] = addressFactory;
        addressArr[3] = _token0;
        addressArr[4] = _token1;
        addressArr[5] = addressPair;

        uintArr[0] = IUniswapV2Factory(addressFactory).allPairsLength();
        uintArr[1] = IUniswapV2Pair(addressPair).decimals();
        uintArr[2] = IUniswapV2Pair(addressPair).totalSupply();
        uintArr[3] = IUniswapV2Pair(addressPair).price0CumulativeLast();
        uintArr[4] = IUniswapV2Pair(addressPair).price1CumulativeLast();

        stringArr[0]=IUniswapV2Pair(addressPair).name();
        stringArr[1]=IUniswapV2Pair(addressPair).symbol();

        return (uintArr, addressArr, stringArr);
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";

contract TaxCreationBlock is Ownable {
    uint256 public taxCreation = 10000000000000000; // 0.01
    address public taxCreationAddress = address(this); // 0.01

    function setTaxCreation(uint256 _amountTax) public onlyOwner {
        taxCreation = _amountTax;
        return;
    }

    function setTaxCreationAddress(address _addressTax) public onlyOwner {
        taxCreationAddress = _addressTax;
        return;
    }

    function sendTaxCreation() payable public {
        require(msg.value >= taxCreation, "taxCreation error");
        if(taxCreationAddress!=address(this)){
            payable(taxCreationAddress).transfer(taxCreation);
        }
        return;
    }
}

// SPDX-License-Identifier: MIT

/**
 * interface IUniswapV2Router
 */

pragma solidity >=0.8.0;

interface IUniswapV2Router {
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

// SPDX-License-Identifier: MIT

/**
 * interface IUniswapV2Factory
 */

pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

/**
 * interface IUniswapV2Pair
 */

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Wallet is Ownable {
    receive() external payable {}
    fallback() external payable {}

    // Transfer Eth
    function transferEth(address _to, uint256 _amount) public onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // Transfer Tokens
    function transferTokens(address addressToken, address _to, uint256 _amount) public onlyOwner {
        IERC20 contractToken = IERC20(addressToken);
        contractToken.transfer(_to, _amount);
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