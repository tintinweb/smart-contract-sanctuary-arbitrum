/**
 *Submitted for verification at Arbiscan.io on 2024-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address owner) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);
}

interface AutomationCompatibleInterface {
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract MaxCapitalRouterV1 is Ownable, ReentrancyGuard, AutomationCompatibleInterface{
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    );

    address[] internal farmingContracts;
    address private multisigWallet;
    AggregatorV3Interface internal WETH9PriceFeed;
    AggregatorV3Interface internal USDCPriceFeed;
    ISwapRouter public swapRouter;
    IWETH public weth;
    IERC20 public usdc;
    uint24 public swapFee = 500;
    uint16 private slippage = 50; //.5%
    uint256 private lastDistro;
    uint256 private totalUsdcSwapped;
    uint256 private totalEthSwapped;
    uint256 public minEthToSwap;
    uint256 public minUSDCToSwap;

    modifier onlyMultisig() {
        require(
            msg.sender == multisigWallet,
            "Caller is not the multisig wallet"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner() || msg.sender == multisigWallet,
            "Caller is not an admin"
        );
        _;
    }

    constructor(
        address _wethAddress,
        address _usdcAddress,
        ISwapRouter _swapRouter
    ) {
        //SmartRouter02 / SmartRouter
        weth = IWETH(_wethAddress);
        usdc = IERC20(_usdcAddress);
        setSwapRouter(_swapRouter);

        multisigWallet = msg.sender;
    }

    receive() external payable {}

    function setMultisigWallet(address _multisigWallet) external onlyMultisig {
        require(_multisigWallet != address(0), "Invalid address");
        multisigWallet = _multisigWallet;
    }

    function setSwapRouter(ISwapRouter _swapRouter) public onlyAdmin {
        swapRouter = _swapRouter;
    }

    function setSlippage(uint16 _slippage) external onlyAdmin {
        slippage = _slippage;
    }

    function setPriceFeeds(address _WETH9, address _USDC) external onlyAdmin {
        require(_WETH9 != address(0), "Invalid address");
        require(_WETH9 != address(0), "Invalid address");
        WETH9PriceFeed = AggregatorV3Interface(_WETH9);
        USDCPriceFeed = AggregatorV3Interface(_USDC);
    }

    function setMinAmtsToSwap(
        uint256 _minEthToSwap,
        uint256 _minUsdcToSwap
    ) external onlyAdmin {
        minEthToSwap = _minEthToSwap;
        minUSDCToSwap = _minUsdcToSwap;
    }

    function getWETH9Price() public view returns (int) {
        (, int WETH9price, , , ) = WETH9PriceFeed.latestRoundData();

        return WETH9price;
    }

    function getUSDCPrice() public view returns (int) {
        (, int USDCprice, , , ) = USDCPriceFeed.latestRoundData();
        return USDCprice;
    }

    function getUSDCSwapped() public view returns (uint256) {
        return totalUsdcSwapped;
    }

    function getEthSwapped() public view returns (uint256) {
        return totalEthSwapped;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded =
            (IWETH(weth).balanceOf(address(this)) >= minEthToSwap) ||
            (IERC20(usdc).balanceOf(address(this)) >= minUSDCToSwap);
    }

    function performUpkeep(bytes calldata) external override{
        uint256 ethBalance = weth.balanceOf(address(this));
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        require(
            ethBalance >= minEthToSwap || usdcBalance >= minUSDCToSwap,
            "Nothing to Swap"
        );
        _swapAndSend();
    }

    function swapAndSend() external onlyAdmin {
        _swapAndSend();
    }

    function _swapAndSend() internal {
        require(block.timestamp >= lastDistro + 60 seconds, "TOO SOON");
        uint256 amountIn = IERC20(usdc).balanceOf(address(this));
        uint256 WETH9price = uint256(getWETH9Price());
        uint256 USDCprice = uint256(getUSDCPrice()) * 10 ** 12;

        uint256 amountInWETH = (amountIn * WETH9price) / USDCprice;
        uint256 amountInUSDC = amountInWETH / 10 ** 12;
        uint256 minAmountOut = amountInUSDC -
            ((amountInUSDC * slippage) / 10000);

        IERC20(usdc).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(usdc),
                tokenOut: address(weth),
                fee: swapFee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(params);

        totalUsdcSwapped += amountIn;
        totalEthSwapped += amountOut;

        IWETH(weth).withdraw(amountOut);

        _distributeETHToContracts();
        lastDistro = block.timestamp;

        emit SwapExecuted(
            address(usdc),
            address(weth),
            amountIn,
            amountOut,
            address(this)
        );
    }

    function _distributeETHToContracts() internal {
        uint256 totalETH = address(this).balance;
        require(totalETH > 0, "No ETH available for distribution");
        require(
            farmingContracts.length > 0,
            "No farming contracts to distribute to"
        );

        uint256 amountPerContract = totalETH / farmingContracts.length;

        for (uint i = 0; i < farmingContracts.length; i++) {
            // Ensure there is no contract address that is zero
            require(
                farmingContracts[i] != address(0),
                "Invalid contract address"
            );

            // Send ETH to each farming contract
            (bool success, ) = farmingContracts[i].call{
                value: amountPerContract
            }("");
            require(success, "ETH transfer failed");
        }
    }

    function swapManual(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external onlyAdmin returns (uint256 amountOut) {
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        IERC20(tokenIn).approve(address(swapRouter), 0);

        emit SwapExecuted(
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            address(this)
        );
    }

    function addFarmingContract(address _contract) external onlyAdmin {
        require(!isContractAdded(_contract), "Contract already added");
        farmingContracts.push(_contract);
    }

    function removeFarmingContract(address _contract) external onlyAdmin {
        require(isContractAdded(_contract), "Contract not found");
        for (uint i = 0; i < farmingContracts.length; i++) {
            if (farmingContracts[i] == _contract) {
                farmingContracts[i] = farmingContracts[
                    farmingContracts.length - 1
                ];
                farmingContracts.pop();
                break;
            }
        }
    }

    function isContractAdded(address _contract) public view returns (bool) {
        for (uint i = 0; i < farmingContracts.length; i++) {
            if (farmingContracts[i] == _contract) {
                return true;
            }
        }
        return false;
    }

    function withdraw(address _beneficiary) public onlyMultisig {
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = _beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyMultisig {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        IERC20(_token).transfer(_beneficiary, amount);
    }
}