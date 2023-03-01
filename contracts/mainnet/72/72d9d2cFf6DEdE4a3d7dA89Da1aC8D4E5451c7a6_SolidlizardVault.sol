pragma solidity >=0.7.5;

import "./base.sol";
import "./vault.sol";

interface IGuage {
    function TOKEN() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function withdrawAll() external;

    function withdraw(uint256 amount) external;

    function depositAll(uint256 tokenId) external;

    function deposit(uint256 amount, uint256 tokenId) external;

    function underlying() external view returns (address);

    function getReward(address account, address[] memory tokens) external;
}

contract SolidlizardVault is Vault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant SLIZ = 0x463913D3a3D3D291667D53B8325c598Eb88D3B0e;
    IGuage public guage;

    uint256 public constant TokenId = 0;

    address[] public rewardTokens;

    constructor(
        address _controller,
        IERC20 _UNDERLYING,
        address _guage
    ) Vault(_controller, _UNDERLYING) {
        guage = IGuage(_guage);
        require(guage.underlying() == address(_UNDERLYING), "!param");
        rewardTokens = new address[](1);
        rewardTokens[0] = SLIZ;

        _UNDERLYING.safeApprove(_guage, type(uint256).max);
    }

    function updateRewardTokens(address[] memory tokens)
        public
        requireControllerAdmin
    {
        rewardTokens = tokens;
    }

    function depositToStrategy() internal override {
        guage.depositAll(TokenId);
    }

    function takeFromStrategy(uint256 amount)
        internal
        override
        returns (uint256)
    {
        guage.getReward(address(this), rewardTokens); // get rewards before withdraw
        guage.withdraw(amount);
        return amount;
    }

    function emergencyExitFromStrategy() internal override {
        guage.getReward(address(this), rewardTokens);
        guage.withdrawAll();
    }

    function balanceOfStrategy() public view override returns (uint256) {
        return guage.balanceOf(address(this));
    }

    function harvestStrategy() internal override {
        guage.getReward(address(this), rewardTokens);
        address _feeCollector = CONTROLLER.feeCollector();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address _token = rewardTokens[i];
            uint256 bal = IERC20(_token).balanceOf(address(this));
            if (bal > 0) {
                IERC20(_token).safeTransfer(_feeCollector, bal);
            }
        }
    }
}