pragma solidity 0.8.18;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MockGMXRewardRouterV2 {

    IERC20 public weth;
    IERC20 public token1;
    IERC20 public token2;
    bool enabled;


    constructor(address _weth, address token1_, address token2_) {
        weth = IERC20(_weth);
        token1 = IERC20(token1_);
        token2 = IERC20(token2_);
    }

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external {
        if(enabled) weth.transfer(msg.sender, 10 ether);
    }

    function enableRewards() external {
        enabled = true;
    }

    function disableRewards() external {
        enabled = false;
    }

    function stakeGmx(uint256 _amount) external {
        IERC20(token1).transferFrom(msg.sender, address(this), _amount);
        IERC20(token2).transfer(msg.sender, _amount);
    }
	function unstakeGmx(uint256 _amount) external {
        IERC20(token2).transferFrom(msg.sender, address(this), _amount);
        IERC20(token1).transfer(msg.sender, _amount);
    }

    function compound() external {

    }

    function claimFees() external {
        if(enabled) weth.transfer(msg.sender, 10 ether);
    }
}