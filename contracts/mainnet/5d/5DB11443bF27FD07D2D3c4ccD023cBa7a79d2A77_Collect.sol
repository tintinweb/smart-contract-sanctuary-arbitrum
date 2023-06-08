// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

library TransferHelper {

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function getBalance(address token,address target) internal view returns (uint){
        (bool success,bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, target));
        require(success);
        return abi.decode(data,(uint));
    }
}

contract Collect{

    mapping(address => bool) exempt;
    mapping (address => address) public inviter;
    uint256  public  duration;
    struct User{
        uint256    totalAmount;  
        uint256    startTime;
        uint256    extracted;
        uint256    rewardETH;
    }    
    mapping(address => User) public userInfo;

    uint256 public  RATE = 10000;
    address public immutable uniswapV2Router;
    address public ghost;
    address public owner;
    address public WETH9;

    uint256 public totalETH;
    uint256 public fullLimit = 30000000e18;
    uint256 public totalGhost;

    uint256 public decimals = 1e2;
    //router:0xE592427A0AEce92De3Edee1F18E0157C05861564
    //weth:0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    constructor(address _uniswapV2Router,address _owner,address _weth9){
        uniswapV2Router = _uniswapV2Router;
        owner = _owner;
        WETH9 = _weth9;
        duration = 90 * 24 * 60 * 60;
    }

    receive() external payable {}

    function updateGhost(address _ghost) external onlyOwner{
        ghost = _ghost;
    }

    function updateOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Collect:Caller is not owner");
        _;
    }

    function rate() public view returns (uint rateValue){
        uint reduce = totalETH * decimals / 100e18;
        //1010000000000000000000
        if (reduce > 1 * decimals && reduce <= 21 * decimals){
            rateValue = RATE - RATE * 2 / 100;
        }else if (reduce > 21 * decimals && reduce <= 45 * decimals){
            //10000 - 
            rateValue = RATE - RATE * 5 / 100;
        }else {
            rateValue = RATE;
        }
    }

    function remaining() public view returns (uint amount){
        amount = (fullLimit - totalGhost) / RATE;
    }

    function binding(address _inviter) external{
        require(inviter[msg.sender] == address(0),"Collect:Repeated binding");
        if (_inviter != owner){
            require(userInfo[_inviter].totalAmount > 0,"Collect:Invalid inivter");
        }
        inviter[msg.sender] = _inviter;
    }

    function provide(uint amount) external payable{
        require(inviter[msg.sender] != address(0),"Collect:Not invited");
        require(remaining() >= amount && msg.value >= amount, "Collect:Invalid amount");
        TransferHelper.safeTransferETH(address(this), amount);
        User storage user = userInfo[msg.sender];
        user.totalAmount += amount * RATE;
        user.startTime = block.timestamp;
        totalETH += amount;
        totalGhost += amount * RATE;
        if (rate() < RATE){
            RATE = rate();
        }
        
        _distributeETH(msg.sender, amount);
        
        uint burnAmount = (amount * 31 / 100) * 70 / 100;
        _burnGhost(burnAmount);

    }

    function getUserRelease(address _user) public view returns (uint _totalGhost,uint _totalETH,uint _extracted,uint _extractable){
        User memory user = userInfo[_user];
        _totalGhost = user.totalAmount;
        _totalETH = user.rewardETH;
        _extracted = user.extracted;
        if(exempt[_user]){
            _extractable = user.totalAmount - user.extracted;
        }else if (block.timestamp >= user.startTime + duration) {
            _extractable = user.totalAmount - user.extracted;
        } else {
            _extractable = user.totalAmount * (block.timestamp - user.startTime) / duration - user.extracted;
        }
    }

    function _distributeETH(address from,uint amount) internal{

        address _inviter = inviter[from];
        uint i = 0;

        while (_inviter != address(0) && i <= 19){
            if (i == 0){
                userInfo[_inviter].rewardETH += amount * 20 / 100;
                _inviter = inviter[_inviter];
                i++;
            } else if (i == 1){
                userInfo[_inviter].rewardETH += amount * 10 / 100;
                _inviter = inviter[_inviter];
                i++;
            }else if(i == 2){
                userInfo[_inviter].rewardETH += amount * 5 / 100;
                _inviter = inviter[_inviter];
                i++;
            }else {
                userInfo[_inviter].rewardETH += amount * 2 / 100;
                _inviter = inviter[_inviter];
                i++;
            }
        }
    }
    
  
    function releaseGhost(address to,uint amount) external {
        (,,,uint _extractable) = getUserRelease(to);
        require(_extractable >= amount,"Collect:Invalid amount");
        uint truthAmount = amount;
        if (!exempt[to]){
            truthAmount = amount * 95 / 100;
        }
        TransferHelper.safeTransfer(ghost,to,truthAmount);
        userInfo[to].extracted += amount;
    }
    
    function withdrawETH(uint amount) external {
        require(amount <= userInfo[msg.sender].rewardETH,"Collect:Invalid amount");
        uint truthAmount = amount;
        if (!exempt[msg.sender]){
            truthAmount = amount * 95 / 100;
        }
        TransferHelper.safeTransferETH(msg.sender,truthAmount);
        userInfo[msg.sender].rewardETH -= amount;
    }

    function withdrawGhostForOwner(address to,uint amountGhost) external onlyOwner{
        TransferHelper.safeTransfer(ghost,to,amountGhost);
    }

    function withdrawETHForOwner(address to,uint amountETH) external onlyOwner{
        TransferHelper.safeTransferETH(to,amountETH);
    }

    function addExempt(address _user,bool isExempt) external onlyOwner{
        exempt[_user] = isExempt;
    }


    function _burnGhost(uint amountIn) internal {
        (bool success,bytes memory data) = WETH9.call{value:amountIn}(abi.encodeWithSignature("deposit()"));
        require(success || data.length == 0);
        (bool sucess,) = WETH9.call(abi.encodeWithSignature("approve(address,uint256)", uniswapV2Router,amountIn));
        require(sucess);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: ghost,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uint beforeBalance = getBalance();
        ISwapRouter(uniswapV2Router).exactInputSingle(params);
        uint afterBalance = getBalance();
        TransferHelper.safeTransfer(ghost, address(this), afterBalance - beforeBalance);
    }

    function getBalance() internal view returns(uint256){
        (bool success,bytes memory data) = ghost.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(success);
        return abi.decode(data,(uint256));
    }
    
}