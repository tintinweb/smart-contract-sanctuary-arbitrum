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
 * It is possible to lock liquidity
 */

 /**
 * Important! Always check address MultiLock, address Swap Router, address token0, address token1, smart contract token. Do Your Own Research.
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

interface iMultiLocks {
    function taxCreation() external view returns (uint256);
    function deployContractMLPool(address addressToken, uint256 _typeToken) external;
    function getMLPoolAllDataByTokens(address _addressToken, address _aOwner, uint256 _key, uint256 _n) external view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory);
}

interface iMultiLockPool {
    function addMultiLock(address[] memory _aOwnerArr, uint256[] memory _amountArr, uint256[] memory _finishTimeArr, string memory _sTextData) payable external returns (bool);
}

contract LPTools is Ownable, Wallet, TaxCreationBlock {
    using SafeMath for uint256;

    event NewLiquidityPool(address indexed newContractTokenAddress, uint256 indexed nPool);

    uint256 public version=1;
    uint256 public amountPools = 0;

    function getVersion() public view returns (uint256) {
        return version;
    }

    // mAddr[aType][address] = true; // 1 - MultiLocks, 2 - Swaps
    mapping(uint256=>mapping(address=>bool)) mAddr;

    constructor () {}

    function cAddr(uint256 aType, address _a) public view returns (bool) {
        return mAddr[aType][_a];
    }

    function setAddr(uint256 aType, address _a, bool bStatus) public onlyOwner {
       mAddr[aType][_a] = bStatus;
    }

    // mPoolsContracts[aPair] = nPool 
    mapping(address => uint256) public mPoolsContracts;

    struct PoolData {
        uint256 nPool;
        address aOwner;
        address aSender;
        address aRouter;
        address token0;
        address token1;
        uint256 nToken0;
        uint256 nToken1;
        uint256 nLiquidity;
        address aPair;
        address aMultiLock;
        address aLock;
        uint256 LPUnlockTime;
        uint256 timeCreation;
    }
    // mPoolsData[nPool] = PoolData
    mapping(uint256 => PoolData) public mPoolsData;

    function calcEthSumm(uint256[] memory nArr, address[] memory aArr) public view returns (uint256) {
        uint256 EthSumm = taxCreation;
        if(aArr[1] == address(0) || aArr[1] == IUniswapV2Router(aArr[2]).WETH()){
            EthSumm = EthSumm.add(nArr[1]);
        }
        if(aArr[0] == address(0) || aArr[0] == IUniswapV2Router(aArr[2]).WETH()){
            EthSumm = EthSumm.add(nArr[0]);
        }
        if(nArr[2] > block.timestamp){
            EthSumm = EthSumm.add(iMultiLocks(aArr[4]).taxCreation());
        }
        return EthSumm;
    }

    function createLiquidityPool(uint256[] memory nArr, address[] memory aArr) payable public {
        require(nArr.length == 3, "nArr 3");
        require(aArr.length == 5, "aArr 5");
        //require(cAddr(2, aArr[2]), "aSwap");

        //uint256 _nToken0 = nArr[0];
        //uint256 _nToken1 = nArr[1];
        //uint256 _LPUnlockTime = nArr[2];

        //address _token0 = aArr[0];
        //address _token1 = aArr[1];
        //address _aRouter = aArr[2];
        //address _aOwner = aArr[3];
        //address _aMultiLock = aArr[4];
        
        require(msg.value >= calcEthSumm(nArr, aArr), "You must send eth");

        //address addressToken1 = aArr[1];
        if(aArr[1] == address(0)){
            aArr[1] = IUniswapV2Router(aArr[2]).WETH();
        }

        address addressFactory = IUniswapV2Router(aArr[2]).factory();
        address aPair = IUniswapV2Factory(addressFactory).getPair(aArr[0], aArr[1]);
        require(aPair == address(0), "LP already exists");
        require(mPoolsContracts[aPair] == 0, "Pool already exists");

        amountPools++;

        if(IERC20(aArr[0]).balanceOf(address(this)) < nArr[0]){
            require(IERC20(aArr[0]).transferFrom(msg.sender, address(this), nArr[0]), "TransferFrom failed. Approval required.");
        }

        require(IERC20(aArr[0]).approve(aArr[2], nArr[0]), "approve failed");
        uint256 nToken0 = 0;
        uint256 nToken1 = 0;
        uint256 nLiquidity = 0;
        if(aArr[1] == IUniswapV2Router(aArr[2]).WETH()){
            (nToken0, nToken1, nLiquidity) = IUniswapV2Router(aArr[2]).addLiquidityETH{value: nArr[1]}(
            aArr[0],
            nArr[0],
            nArr[0],
            nArr[1],
            address(this),
            block.timestamp
            );
        } else {
            (nToken0, nToken1, nLiquidity) = IUniswapV2Router(aArr[2]).addLiquidity(
            aArr[0],
            aArr[1],
            nArr[0],
            nArr[1],
            nArr[0],
            nArr[1],
            address(this),
            block.timestamp
            );
        }

        addressFactory = IUniswapV2Router(aArr[2]).factory();
        aPair = IUniswapV2Factory(addressFactory).getPair(aArr[0], aArr[1]);

        // lock LP
        if(nArr[2] > block.timestamp){
            //require(cAddr(1, aArr[4]), "aMultiLock");

            // create lock pool
            (uint256[] memory nArrPoolAllData, address[] memory aArrPoolAllData, bool[] memory bArrPoolAllData, string[] memory sArrPoolAllData) = iMultiLocks(aArr[4]).getMLPoolAllDataByTokens(aPair, address(0), 0, 0);
            if(aArrPoolAllData[0] == address(0)){
                iMultiLocks(aArr[4]).deployContractMLPool(aPair, 1);
                (nArrPoolAllData, aArrPoolAllData, bArrPoolAllData, sArrPoolAllData) = iMultiLocks(aArr[4]).getMLPoolAllDataByTokens(aPair, address(0), 0, 0);
            }

            address[] memory _aOwnerArr = new address[](1);
            _aOwnerArr[0] = aArr[3];
            uint256[] memory _amountArr = new uint256[](1);
            _amountArr[0] = nLiquidity;
            uint256[] memory _finishTimeArr = new uint256[](1);
            _finishTimeArr[0] = nArr[2];

            require(IERC20(aPair).approve(aArrPoolAllData[0], _amountArr[0]), "approve failed");
            iMultiLockPool(aArrPoolAllData[0]).addMultiLock{value: iMultiLocks(aArr[4]).taxCreation()}(_aOwnerArr, _amountArr, _finishTimeArr, "");
            mPoolsData[amountPools].aLock = aArrPoolAllData[0];
        } else {
            IERC20(aPair).transfer(aArr[3], nLiquidity);
            nArr[2]=0;
        }

        mPoolsContracts[aPair] = amountPools;

        mPoolsData[amountPools].nPool = amountPools;
        mPoolsData[amountPools].aPair = aPair;
        
        mPoolsData[amountPools].aOwner = aArr[3];
        mPoolsData[amountPools].aSender = msg.sender;
        mPoolsData[amountPools].aRouter = aArr[2];
        mPoolsData[amountPools].token0 = aArr[0];
        mPoolsData[amountPools].token1 = aArr[1];
        mPoolsData[amountPools].nToken0 = nToken0;
        mPoolsData[amountPools].nToken1 = nToken1;
        mPoolsData[amountPools].nLiquidity = nLiquidity;
        mPoolsData[amountPools].aMultiLock = aArr[4];
        mPoolsData[amountPools].LPUnlockTime = nArr[2];
        mPoolsData[amountPools].timeCreation = block.timestamp;

        emit NewLiquidityPool(aPair, amountPools);
    }

    function getLiquidityPoolAllData(uint256 _nPool, address _addressAccount, address _addressSpender) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256[] memory uintArr = new uint256[](50);
        address[] memory addressArr = new address[](50);
        bool[] memory boolArr = new bool[](50);
        string[] memory stringArr = new string[](50);

        if(mPoolsData[_nPool].nPool==0){
            return (uintArr, addressArr, boolArr, stringArr);
        }

        // uintArr
        uintArr[0] = mPoolsData[_nPool].nPool;
        uintArr[1] = mPoolsData[_nPool].nToken0;
        uintArr[2] = mPoolsData[_nPool].nToken1;
        uintArr[3] = mPoolsData[_nPool].nLiquidity;
        uintArr[4] = mPoolsData[_nPool].timeCreation;
        uintArr[5] = mPoolsData[_nPool].LPUnlockTime;
        uintArr[9] = amountPools;
        uintArr[10] = version;

        // addressArr
        addressArr[0] = mPoolsData[_nPool].aOwner;
        addressArr[1] = mPoolsData[_nPool].aRouter;
        addressArr[2] = mPoolsData[_nPool].token0;
        addressArr[3] = mPoolsData[_nPool].token1;
        addressArr[4] = mPoolsData[_nPool].aPair;
        addressArr[5] = mPoolsData[_nPool].aSender;
        addressArr[6] = _addressAccount;
        addressArr[7] = _addressSpender;
        addressArr[8] = mPoolsData[_nPool].aMultiLock;
        addressArr[9] = mPoolsData[_nPool].aLock;

        return (uintArr, addressArr, boolArr, stringArr);
    }

    function getTokenAllDataByPair(address _aPair, address _aOwner, address _addressSpender) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256 _nPool = mPoolsContracts[_aPair];
        return getLiquidityPoolAllData(_nPool, _aOwner, _addressSpender);
    }

    function getLPTokensData(address _aRouter, address _token0, address _token1) public view returns (uint256[] memory, address[] memory, string[] memory) {
        uint256[] memory uintArr = new uint256[](50);
        address[] memory addressArr = new address[](50);
        string[] memory stringArr = new string[](50);

        address addressWETH = IUniswapV2Router(_aRouter).WETH();
        if(_token0==address(0)){ _token0 = addressWETH; }
        if(_token1==address(0)){ _token1 = addressWETH; }

        address addressFactory = IUniswapV2Router(_aRouter).factory();
        address aPair = IUniswapV2Factory(addressFactory).getPair(_token0, _token1);

        addressArr[0] = _aRouter;
        addressArr[1] = addressWETH;
        addressArr[2] = addressFactory;
        addressArr[3] = _token0;
        addressArr[4] = _token1;
        addressArr[5] = aPair;

        uintArr[0] = IUniswapV2Factory(addressFactory).allPairsLength();
        uintArr[1] = IUniswapV2Pair(aPair).decimals();
        uintArr[2] = IUniswapV2Pair(aPair).totalSupply();
        uintArr[3] = IUniswapV2Pair(aPair).price0CumulativeLast();
        uintArr[4] = IUniswapV2Pair(aPair).price1CumulativeLast();
        uintArr[5] = mPoolsContracts[aPair]; // nPool

        stringArr[0]=IUniswapV2Pair(aPair).name();
        stringArr[1]=IUniswapV2Pair(aPair).symbol();

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