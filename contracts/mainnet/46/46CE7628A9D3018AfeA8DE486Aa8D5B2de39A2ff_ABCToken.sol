// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICamelotFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo()
        external
        view
        returns (uint _ownerFeeShare, address _feeTo);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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

contract ABCToken is Context, Ownable, IERC20 {
    function totalSupply() external pure override returns (uint256) {
        if (TOKEN_TOTAL_SUPPLY == 0) {
            revert();
        }
        return TOKEN_TOTAL_SUPPLY;
    }

    function decimals() external pure override returns (uint8) {
        if (TOKEN_TOTAL_SUPPLY == 0) {
            revert();
        }
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private liquidityAdd;
    mapping(address => bool) private isLpPair;
    mapping(address => uint256) private balance;

    uint256 public mintPricePerAmount;
    uint256 public constant TOKEN_TOTAL_SUPPLY = 1_008_600_000_000 * 10 ** 9;
    uint256 public constant MAX_MINT_AMOUNT = 200;
    uint256 public constant TOKENS_PER_MINT = 35301000 * 10 ** 9;
    uint256 public maxClaims = 10086;
    uint256 public claimAmount;

    address public immutable deployer;
    address public addr1 = 0x3993cF3D454C54d593C8e6bff0df91E441f09EAA;
    address public addr2 = 0x243b28A8D31458dd5A1C01edC979e35E3657b70C;
    address public addr3 = 0xad36d7705899199263FB5D2418928Cb7F015a43e;

    bool public isClaimingActive = false;
    bool public isMintingActive = false;

    uint256 public totalMinted;
    uint256 public totalClaimed;

    mapping(address => uint256) public claimableTokens;

    mapping(address => bool) public hasClaimed;
    mapping(address => uint256) public mintAmounts;
    mapping(address => bool) public automatedMarketMakerPairs;

    event Claimed(address indexed claimer, uint256 amount);
    event Minted(address indexed recipient, uint256 mintAmount);

    uint256 public buyfee = 90;
    uint256 public sellfee = 90;
    uint256 public constant fee_denominator = 100;

    ICamelotFactory private immutable factory;
    ICamelotRouter private immutable swapRouter;
    IWETH private immutable WETH;
    string private constant _name = "ABCToken";
    string private constant _symbol = "ABC";
    uint8 private constant _decimals = 9;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public lpPair;
    bool private inSwap;

    modifier inSwapFlag() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event _setPresaleAddress(address account, bool enabled);
    event _changePair(address newLpPair);

    constructor() {
        deployer = msg.sender;
        claimAmount = ((TOKEN_TOTAL_SUPPLY * 10) / 100) / maxClaims;

        factory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
        swapRouter = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
        WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        liquidityAdd[msg.sender] = true;
        balance[msg.sender] = ((TOKEN_TOTAL_SUPPLY * 30) / 100);
        balance[addr1] = ((TOKEN_TOTAL_SUPPLY * 5) / 100);
        balance[addr2] = ((TOKEN_TOTAL_SUPPLY * 10) / 100);
        balance[addr3] = ((TOKEN_TOTAL_SUPPLY * 10) / 100);
        balance[address(this)] = ((TOKEN_TOTAL_SUPPLY * 45) / 100);
        emit Transfer(address(0), msg.sender, TOKEN_TOTAL_SUPPLY);
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);
    }

    function initializePair() external onlyOwner {
        address pair = factory.createPair(address(WETH), address(this));
        lpPair = pair;
        isLpPair[lpPair] = true;
    }

    function claim() external {
        require(isClaimingActive, "Claiming is not active at the moment");
        require(
            claimableTokens[msg.sender] == claimAmount,
            "Invalid parter user"
        );
        require(!hasClaimed[msg.sender], "You have already claimed");
        require(
            totalClaimed + claimAmount <= ((TOKEN_TOTAL_SUPPLY * 10) / 100),
            "Maximum claims reached"
        );

        _transfer(address(this), msg.sender, claimAmount);
        claimableTokens[msg.sender] = 0;
        hasClaimed[msg.sender] = true;
        totalClaimed += claimAmount;

        emit Claimed(msg.sender, claimAmount);
    }

    function mint(uint256 mintAmount) public payable {
        require(isMintingActive, "Minting is not active at the moment");
        require(
            mintAmount >= 1 && mintAmount <= MAX_MINT_AMOUNT,
            "mintAmount must be between 1 and 200"
        );
        require(
            mintAmounts[msg.sender] + mintAmount <= MAX_MINT_AMOUNT,
            "Exceed max mint amount"
        );
        require(
            totalMinted + mintAmount * TOKENS_PER_MINT <=
                ((TOKEN_TOTAL_SUPPLY * 35) / 100),
            "Maximum mints reached"
        );

        uint256 totalCost = mintAmount * mintPricePerAmount;
        require(msg.value >= totalCost, "Not enough ETH sent");

        (bool success, ) = payable(deployer).call{value: msg.value}("");
        require(success, "Transfer to deployer failed");

        _transfer(address(this), msg.sender, mintAmount * TOKENS_PER_MINT);
        mintAmounts[msg.sender] += mintAmount;

        totalMinted += mintAmount * TOKENS_PER_MINT;

        emit Minted(msg.sender, mintAmount);
    }

    function toggleClaiming() public onlyOwner {
        isClaimingActive = !isClaimingActive;
    }

    function toggleMinting() public onlyOwner {
        isMintingActive = !isMintingActive;
    }

    function setMintingPrice(uint256 _price) public onlyOwner {
        mintPricePerAmount = _price * 10 ** 13;
    }

    function setTradeTax(uint256 _buyFee, uint256 _sellFee) public onlyOwner {
        buyfee = _buyFee;
        sellfee = _sellFee;
    }

    function setClaimRecipients(
        address[] calldata _recipients
    ) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            claimableTokens[_recipients[i]] = claimAmount;
        }
    }

    receive() external payable {}

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transfer(sender, recipient, amount);
    }

    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) {
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function changeLpPair(address newPair) external onlyOwner {
        isLpPair[newPair] = true;
        emit _changePair(newPair);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (is_sell(from, to) && !inSwap) {
            uint256 contractTokenBalance = balanceOf(address(this));
            internalSwap(contractTokenBalance);
        }

        balance[from] -= amount;
        uint256 amountAfterFee = takeTaxes(
            is_buy(from, to),
            is_sell(from, to),
            amount,
            from
        );
        balance[to] += amountAfterFee;
        emit Transfer(from, to, amountAfterFee);

        return true;
    }

    function takeTaxes(
        bool isbuy,
        bool issell,
        uint256 amount,
        address from
    ) internal returns (uint256) {
        uint256 fee;
        if (isbuy) fee = buyfee;
        else if (issell) fee = sellfee;
        if (fee == 0) return amount;
        uint256 feeAmount = (amount * fee) / fee_denominator;
        if (feeAmount > 0) {
            _transfer(from, address(this), amount);
            balance[address(this)] += feeAmount;
            internalSwap(feeAmount);
        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (
            _allowances[address(this)][address(swapRouter)] != type(uint256).max
        ) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try
            swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                contractTokenBalance,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }
        bool success;

        if (address(this).balance > 0) {
            (success, ) = deployer.call{
                value: address(this).balance,
                gas: 35000
            }("");
        }
    }
}