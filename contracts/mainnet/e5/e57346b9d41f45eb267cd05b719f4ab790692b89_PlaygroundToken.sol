/**
 *Submitted for verification at Arbiscan on 2022-10-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPlaygroundFactory {
    function createPair(
        address tokenA,
        address tokenB,
        address router
    ) external returns (address pair);
}

interface IPlaygroundPair {
    function setFeeToken(address _feeToken) external;

    function setTotalFee(uint256 _totalFee) external returns (bool);
}

interface IPlaygroundRouter {
    function factory() external view returns (address);

    function WETH() external view returns (address);
}

contract PlaygroundToken is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    string private constant _name = "PlaygroundToken";
    string private constant _symbol = "PlaygroundToken";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 1000000000 * 10**18;

    IPlaygroundRouter public playgroundRouter;
    address public playgroundPair;
    address public WETH;

    uint256 private _fee1 = 50; // 5%, change name of this variable for your use case
    uint256 private _fee2 = 20; // 2%, change name of this variable for your use case

    uint256 public _totalFee = _fee1 + _fee2;

    address private _fee1Wallet = address(0x5EE5AE0a3dB3E4351549B229B409C420EB5D0740); // change name and value of this variable for your use case
    address private _fee2Wallet = address(0x5EE5AE0a3dB3E4351549B229B409C420EB5D0740); // change name and value of this variable for your use case;

    modifier onlyProtocol() {
        require(
            msg.sender == address(playgroundRouter) ||
                msg.sender == address(playgroundPair),
            "PlaygroundToken: caller is not the router or the pair"
        );
        _;
    }

    event FeesClaimed(address indexed feeToken, uint256 feeAmount);

    constructor(address _router) {
        _balances[_msgSender()] = _totalSupply;

        // Create a Playground pair for this new token
        playgroundRouter = IPlaygroundRouter(_router);
        WETH = playgroundRouter.WETH();
        playgroundPair = IPlaygroundFactory(playgroundRouter.factory()).createPair(
            address(this),
            WETH,
            address(playgroundRouter)
        );

        // Set the fee token to be the WETH
        IPlaygroundPair(playgroundPair).setFeeToken(WETH);

        // Set the total fee
        IPlaygroundPair(playgroundPair).setTotalFee(_totalFee);

        // exclude from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // temporary set fee wallets to owner.
        // Remove this line and set the fee wallets to your own addresses
        _fee1Wallet = owner();
        _fee2Wallet = owner();

        _approve(_msgSender(), address(playgroundRouter), type(uint256).max);

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalFee() public view returns (uint256) {
        return _totalFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        _transfer(sender, recipient, amount);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "PlaygroundToken: transfer amount exceeds allowance"
            );

            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "PlaygroundToken: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address"); // use 0xdead for burn
        require(amount > 0, "Transfer amount must be greater than zero");

        // do other checks here, like max tx amount, max wallet amount, etc.

        bool takeFee = true;

        // if account in _isExcludedFromFee, then no fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        // execute transfer
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        // handle other transfer logic if needed

        // transfer amount, it will take tax, burn, liquidity fee
        _transferStandard(sender, recipient, amount);

        if (!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeAllFee() private {
        if (_totalFee == 0) return;
        IPlaygroundPair(playgroundPair).setTotalFee(0);
    }

    function restoreAllFee() private {     
        IPlaygroundPair(playgroundPair).setTotalFee(_totalFee);
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function updateFees(uint256 fee1, uint256 fee2) external onlyOwner {
        _fee1 = fee1;
        _fee2 = fee2;
        _totalFee = _fee1 + _fee2;
        IPlaygroundPair(playgroundPair).setTotalFee(_totalFee);
    }

    function updateFeeWallets(address fee1Wallet, address fee2Wallet)
        external
        onlyOwner
    {
        _fee1Wallet = fee1Wallet;
        _fee2Wallet = fee2Wallet;
    }

    function updateFeeToken(address feeToken) external onlyOwner {
        // only one of the pair can be fee token
        IPlaygroundPair(playgroundPair).setFeeToken(feeToken);
    }

    function setNewRouter(address _router) external onlyOwner {
        playgroundRouter = IPlaygroundRouter(_router);
        WETH = playgroundRouter.WETH();
        playgroundPair = IPlaygroundFactory(playgroundRouter.factory()).createPair(
            address(this),
            WETH,
            address(playgroundRouter)
        );
        IPlaygroundPair(playgroundPair).setFeeToken(WETH);
        IPlaygroundPair(playgroundPair).setTotalFee(_totalFee);
        _approve(_msgSender(), address(playgroundRouter), type(uint256).max);
    }

    function disableFees() external onlyOwner {
        IPlaygroundPair(playgroundPair).setFeeToken(address(0));
        IPlaygroundPair(playgroundPair).setTotalFee(0);
    }

    // Claim fees, called by pair contract and must be defined for all tokens
    function claimFees(uint256 amount, address token) public onlyProtocol {
        // get fee token allowance for contract
        uint256 tokenAllowance = IERC20(token).allowance(
            msg.sender,
            address(this)
        );
        if (tokenAllowance >= amount) {
            // prep to transfer fee token to fee wallets
            uint256 currentTokenBalance = IERC20(token).balanceOf(
                address(this)
            );
            // transfer from pair to contract
            IERC20(token).transferFrom(msg.sender, address(this), amount);

            // get amount of fee token transferred
            uint256 newTokenBalance = IERC20(token).balanceOf(address(this));
            uint256 tokenAmount = newTokenBalance - currentTokenBalance;

            // split fees as desired
            uint256 fee1Amount = (tokenAmount * _fee1) / _totalFee;
            uint256 fee2Amount = (tokenAmount * _fee2) / _totalFee;

            // transfer fee token to fee wallets
            IERC20(token).transfer(_fee1Wallet, fee1Amount);
            IERC20(token).transfer(_fee2Wallet, fee2Amount);

            emit FeesClaimed(token, tokenAmount);
        }
    }

    // receive ETH
    receive() external payable {}

    // send stuck ETH to owner
    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // send stuck ERC20 to owner
    function withdrawERC20(IERC20 tokenAddress) external onlyOwner {
        uint256 balance = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(owner(), balance);
    }
}