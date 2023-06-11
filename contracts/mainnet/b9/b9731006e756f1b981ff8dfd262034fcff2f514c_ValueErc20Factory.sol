/**
 *Submitted for verification at Arbiscan on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUniSwapV3Pool {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function refundETH() external payable;
    function WETH9() external view returns (address);
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

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract CommonUtil {
    address internal immutable blackHole =
        0x000000000000000000000000000000000000dEaD;

    IUniSwapV3Pool internal immutable uniSwapV3Pool =
        IUniSwapV3Pool(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    
    address public immutable wethAddress;

    constructor(){
        wethAddress = uniSwapV3Pool.WETH9();
    }

    receive() external payable {}

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    struct tokenAddInfo {
        address token;
        uint256 amount;
    }

}

contract ValueErc20 is CommonUtil, ERC20, Ownable {
    uint256 public _maxMintCount;
    uint256 public _mintPrice;
    uint256 public _maxMintCountPerAddress;

    mapping(address => uint256) internal _mintCounts;

    uint256 public _mintedCounts;

    address public _devAddress;
    address public _deplyAddress;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintCountPerAddress,
        uint256 mintPrice,
        address factoryContract,
        address devAddress,
        address deplyAddress
    ) ERC20(symbol, name) {
        _maxMintCount = maxMintCount;
        _mintPrice = mintPrice;
        _devAddress = devAddress;
        _deplyAddress = deplyAddress;
        _maxMintCountPerAddress = maxMintCountPerAddress;
        _mint(factoryContract, totalSupply*1/100_000);
        _mint(devAddress, totalSupply*500/100_000);
        _mint(deplyAddress, totalSupply*500/100_000);
        _mint(address(this), totalSupply*98_999/100_000);
        _approve(address(this), address(uniSwapV3Pool), type(uint256).max);
    }


    function mint(uint256 mintCount, address receiveAds) external payable {
        require(mintCount > 0, "Invalid mint count");
        require(
            mintCount <= _maxMintCountPerAddress,
            "Exceeded maximum mint count per address"
        );
        require(msg.value >= mintCount * _mintPrice, "Insufficient balance");
        require(
            _mintCounts[msg.sender] + mintCount <= _maxMintCountPerAddress,
            "Over the maxMintCountPerAddress"
        );

        uint256 ethAmount = (msg.value * 99) / 100;
        uint256 mintAmount = (totalSupply() * 98_999 * mintCount) /
            (_maxMintCount * 100_000);

        // Add liquidity to black hole lp
        addLiquidity(ethAmount, mintAmount);
        // Transfer minted tokens from contract to the sender
        _transfer(address(this), receiveAds, mintAmount);

        _mintCounts[msg.sender] += mintCount;
        _mintedCounts += mintCount;
    }

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) internal {
        address tokenAddress = address(this);
        tokenAddInfo memory token0;
        tokenAddInfo memory token1;
        // Create pool
        if (tokenAddress < wethAddress) {
            token0 = tokenAddInfo(tokenAddress, tokenAmount);
            token1 = tokenAddInfo(wethAddress, ethAmount);
        } else {
            token0 = tokenAddInfo(wethAddress, ethAmount);
            token1 = tokenAddInfo(tokenAddress, tokenAmount);
        }
        IUniSwapV3Pool.MintParams memory params = IUniSwapV3Pool.MintParams(
            token0.token,
            token1.token,
            uint24(3000),
            int24(-887220),
            int24(887220),
            token0.amount,
            token1.amount,
            0,
            0,
            blackHole,
            block.timestamp + 1200
        );
        // Add liquidity
        uniSwapV3Pool.mint{value: ethAmount}(params);
        uniSwapV3Pool.refundETH();
    }

    function emergencyWithDrawToken(
        address token,
        address to,
        uint256 value
    ) external {
        require(token != address(this) && msg.sender == _devAddress, "rug?");
        safeTransfer(token, to, value);
    }

    function devAward() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient ETH balance.");
        safeTransferETH(payable(_devAddress), balance);
    }
}

contract ValueErc20Factory is CommonUtil, Ownable {
    address public devAddress;
    mapping(string => address) public _tokenContracts;
    TokenInfo[] public tokens;

    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 maxMintCount;
        uint256 maxMintCountPerAddress;
        uint256 mintPrice;
        address creator;
    }

    event TokenCreated(
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintCountPerAddress,
        uint256 mintPrice,
        address factoryContract,
        address devAddress,
        address creator
    );

    constructor() {
        devAddress = _msgSender();
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintCountPerAddress,
        uint256 mintPrice,
        uint160 sqrtPriceX96
    ) external payable {
        require(bytes(name).length == 4, "Invalid token name length");
        require(
            _tokenContracts[name] == address(0),
            "Token name already exists"
        );
        require(msg.value == 0.0001 ether, "Incorrect payment amount");
        // Create an ERC20 token contract
        bytes32 _salt = bytes32(bytes(name));
        ValueErc20 token = new ValueErc20{salt: _salt}(
            name,
            symbol,
            totalSupply,
            maxMintCount,
            maxMintCountPerAddress,
            mintPrice,
            address(this),
            devAddress,
            msg.sender
        );
        // Add liquidity and send to black hole
        createAndAddLiquidity(
            address(token),
            totalSupply*1/100_000,
            msg.value,
            sqrtPriceX96
        );
        require(address(this).balance< 0.00001 ether ,"Price exceeds slippage");
        require(token.balanceOf(address(this))< totalSupply*1/1_000_000 ,"Price exceeds slippage");
        // Give up admin privileges
        token.transferOwnership(blackHole);
        _tokenContracts[name] = address(token);
        TokenInfo memory tokenInfo = TokenInfo(
            address(token),
            name,
            symbol,
            totalSupply,
            maxMintCount,
            maxMintCountPerAddress,
            mintPrice,
            msg.sender
        );
        // Add to configuration
        tokens.push(tokenInfo);
        emit TokenCreated(
            address(token),
            name,
            symbol,
            totalSupply,
            maxMintCount,
            maxMintCountPerAddress,
            mintPrice,
            address(this),
            devAddress,
            msg.sender
        );
    }

    function createAndAddLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint160 sqrtPriceX96
    ) internal {
        IERC20 token = IERC20(tokenAddress);
        // Approve to the pool
        token.approve(address(uniSwapV3Pool), tokenAmount);
        // Create pool
        tokenAddInfo memory token0;
        tokenAddInfo memory token1;
        // Create pool
        if (tokenAddress < wethAddress) {
            token0 = tokenAddInfo(tokenAddress, tokenAmount);
            token1 = tokenAddInfo(wethAddress, ethAmount);
        } else {
            token0 = tokenAddInfo(wethAddress, ethAmount);
            token1 = tokenAddInfo(tokenAddress, tokenAmount);
        }

        uniSwapV3Pool.createAndInitializePoolIfNecessary(
            token0.token,
            token1.token,
            uint24(3000),
            sqrtPriceX96
        );

        IUniSwapV3Pool.MintParams memory params = IUniSwapV3Pool.MintParams(
            token0.token,
            token1.token,
            uint24(3000),
            int24(-887220),
            int24(887220),
            token0.amount,
            token1.amount,
            0,
            0,
            blackHole,
            block.timestamp + 1200
        );
        // Add liquidity
        uniSwapV3Pool.mint{value: ethAmount}(params);
        uniSwapV3Pool.refundETH();
    }

    function getTokensByPage(uint256 page, uint256 pageSize)
        external
        view
        returns (TokenInfo[] memory)
    {
        require(page > 0, "Invalid page number");
        require(pageSize > 0, "Invalid page size");

        uint256 start = (page - 1) * pageSize;
        uint256 end = start + pageSize;
        if (end > tokens.length) {
            end = tokens.length;
        }

        TokenInfo[] memory result = new TokenInfo[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = tokens[i];
        }
        return result;
    }

    function getTokenCount() external view returns (uint256) {
        return tokens.length;
    }

    function emergencyWithDrawToken(
        address token,
        address to,
        uint256 value
    ) external onlyOwner{
        safeTransfer(token, to, value);
    }

    function devAward() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient ETH balance.");
        safeTransferETH(payable(devAddress), balance);
    }
}