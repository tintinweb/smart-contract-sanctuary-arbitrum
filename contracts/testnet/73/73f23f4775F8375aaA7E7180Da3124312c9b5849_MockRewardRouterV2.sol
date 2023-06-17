pragma solidity 0.8.18;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MockRewardRouterV2 {

    IERC20 public weth;
    IERC20 public glp;

    constructor(address _weth, address _glp) {
        weth = IERC20(_weth);
        glp = IERC20(_glp);
    }

    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256) {
        // weth.transferFrom(msg.sender, address(this), _amount);
        // glp.transfer(msg.sender, _amount);
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
        weth.transfer(msg.sender, 1e18);
    }
}