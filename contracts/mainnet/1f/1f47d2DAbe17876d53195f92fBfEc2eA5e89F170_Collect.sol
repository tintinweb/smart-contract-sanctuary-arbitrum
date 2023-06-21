// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV3SwapCallback {
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

}


contract Synchron{

    struct PoolInfo{
        uint wholeETH;
        uint surplusETH;
        uint occupyGhost;
        uint surplusGhost;
    }

    struct PersonalInfo{
        uint personalTotalETH;
        uint personalExtractedETH;
        uint personalExtractableETH;
        uint personalTotalGhost;
        uint personalExtractedGhost;
        uint personalExtractableGhost;
        uint personalReleaseGhost;
    }

    struct User{
        uint256    totalGhostAmount;  
        uint256    extractedGhost;
        uint256    totalRewardETH;
        uint256    extractedETH;
        uint256    stakingTime;
    }    
    mapping(address => User) public userInfo;

}

contract Collect is Synchron{

    mapping(address => bool) exempt;
    mapping (address => address) public inviter;
    uint256  public  startTime;
    uint256  public  duration = 90 * 24 * 60 * 60;
    uint256 public  RATE = 10000;
    address public immutable uniswapV2Router;
    address public ghost;
    address public owner;
    address public WETH9;

    uint256 totalETH;
    uint256 fullLimit = 30000000e18;
    uint256 totalGhost;
    bool    public isBurn;
    uint256 decimals = 1e2;


    constructor(address _uniswapV2Router,address _owner,address _weth9){
        uniswapV2Router = _uniswapV2Router;
        owner = _owner;
        WETH9 = _weth9;
    }

    receive() external payable {}

    modifier onlyOwner(){
        require(msg.sender == owner,"Collect:Caller is not owner");
        _;
    }

    function updateGhost(address _ghost) external onlyOwner{
        ghost = _ghost;
    }

    function updateOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    function openBurn(bool _isBurn) external onlyOwner{
        isBurn = _isBurn;
    }

    function updateStartTime() external onlyOwner{
        startTime = block.timestamp;
    }

    function addExempt(address _user,bool isExempt) external onlyOwner{
        exempt[_user] = isExempt;
    }

    function collectGhost(address to,uint amountGhost) external onlyOwner{
        TransferHelper.safeTransfer(ghost,to,amountGhost);
    }

    function collectETH(address to,uint amountETH) external onlyOwner{
        TransferHelper.safeTransferETH(to,amountETH);
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////onlyOnwer///////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function rate() public view returns (uint rateValue){
        uint reduce = totalETH * decimals / 100e18;
        if (reduce > 1 * decimals && reduce <= 21 * decimals){
            rateValue = RATE - RATE * 2 / 100;
        }else if (reduce > 21 * decimals && reduce <= 45 * decimals){
            rateValue = RATE - RATE * 5 / 100;
        }else {
            rateValue = RATE;
        }
    }

    function remaining() internal view returns (uint amount){
        amount = (fullLimit - totalGhost) / RATE;
    }

    function binding(address _inviter) external{
        require(inviter[msg.sender] == address(0),"Collect:Repeated binding");
        if (_inviter != owner){
            require(userInfo[_inviter].totalGhostAmount > 0,"Collect:Invalid inivter");
        }
        inviter[msg.sender] = _inviter;
    }

    function provide(uint amount) external payable{
        require(inviter[msg.sender] != address(0),"Collect:Not invited");
        require(remaining() >= amount && msg.value >= amount && amount >= 1e17, "Collect:Invalid amount");
        TransferHelper.safeTransferETH(address(this), amount);
        User storage user = userInfo[msg.sender];
        require(user.totalGhostAmount == 0,"Collect:Only ownec");
        user.totalGhostAmount += amount * RATE;
        totalETH += amount;
        totalGhost += amount * RATE;
        user.stakingTime = block.timestamp;
        if (rate() < RATE){
            RATE = rate();
        }
        _distributeETH(msg.sender, amount);
        if (isBurn){
            uint burnAmount = (amount * 31 / 100) * 70 / 100;
            _burnGhost(burnAmount);
        }
    }

    function _distributeETH(address from,uint amount) internal{
        address _inviter = inviter[from];
        uint i = 0;

        while (_inviter != address(0) && i <= 19){
            if (i == 0){
                userInfo[_inviter].totalRewardETH += amount * 20 / 100;
                _inviter = inviter[_inviter];
                i++;
            } else if (i == 1){
                userInfo[_inviter].totalRewardETH += amount * 10 / 100;
                _inviter = inviter[_inviter];
                i++;
            }else if(i == 2){
                userInfo[_inviter].totalRewardETH += amount * 5 / 100;
                _inviter = inviter[_inviter];
                i++;
            }else {
                userInfo[_inviter].totalRewardETH += amount * 2 / 100;
                _inviter = inviter[_inviter];
                i++;
            }
        }
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
        uint amountOut = ISwapRouter(uniswapV2Router).exactInputSingle(params);
        TransferHelper.safeTransfer(ghost, address(0), amountOut);
    }

    function getPoolInfo() external view returns(PoolInfo memory){
        return PoolInfo(totalETH,remaining(),totalGhost,fullLimit - totalGhost);
    }

    function _getStartTime(address addr) internal view returns(uint256){
        uint start;
        User memory user = userInfo[addr];
        if (startTime > 0){
            if(user.stakingTime >= startTime) start = user.stakingTime;
            if(user.stakingTime < startTime) start = startTime;
        }
        return start;
    }

    function getUserRelease(address _userAddr) public view returns(PersonalInfo memory){
        User memory user = userInfo[_userAddr];
        uint _extractableGhost;
        uint start = _getStartTime(_userAddr);
        if(start > 0){
            if(block.timestamp >= start){
                if(exempt[_userAddr]){
                    _extractableGhost = user.totalGhostAmount - user.extractedGhost;     
                }else if(block.timestamp >= start + duration){
                    _extractableGhost = user.totalGhostAmount - user.extractedGhost;    
                }else {
                    _extractableGhost = user.totalGhostAmount * (block.timestamp - start) / duration - user.extractedGhost;   
                }
            }
        }
        
        return PersonalInfo(
            user.totalRewardETH,
            user.extractedETH,
            user.totalRewardETH - user.extractedETH,
            user.totalGhostAmount,
            user.extractedGhost,
            _extractableGhost,
            _extractableGhost + user.extractedGhost
        );
    }

    function releaseGhost(address to,uint amount) external {
        PersonalInfo memory person = getUserRelease(to);
        require(person.personalExtractableGhost >= amount,"Collect:Invalid amount");
        uint truthAmount = amount;
        if (!exempt[to]){
            truthAmount = amount * 95 / 100;
        }
        TransferHelper.safeTransfer(ghost,to,truthAmount);
        userInfo[to].extractedGhost += amount;
    }

    function withdrawETH(uint amount) external {
        PersonalInfo memory person = getUserRelease(msg.sender);
        require(amount <= person.personalExtractableETH,"Collect:Invalid amount");
        uint truthAmount = amount;
        if (!exempt[msg.sender]){
            truthAmount = amount * 95 / 100;
        }
        TransferHelper.safeTransferETH(msg.sender,truthAmount);
        userInfo[msg.sender].extractedETH += amount;
    }



}