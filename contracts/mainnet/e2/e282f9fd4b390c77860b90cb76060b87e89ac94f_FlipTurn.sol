// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ILiquidation {
    function swapExactAmountOut(
        address _liquidationPair,
        address _receiver,
        uint256 _amountOut,
        uint256 _amountInMax,
        uint256 _deadline
    ) external returns (uint256);
}

interface IVault {
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);
}

contract FlipTurn {
    address public owner;
    address constant ONEINCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    address constant LIQUIDATION_ROUTER = 0x7B4a60964994422BF19AE48a90Fbff806767Db73;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function approveToken(address tokenAddress, address spender, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).approve(spender, amount);
    }

    function lapThePool(
        address _liquidationPair,
        uint256 _amountOut,
        uint256 _amountInMax,
        address _vaultAddress, 
        bytes calldata swapBackData
    ) external onlyOwner {
        ILiquidation liquidationRouter = ILiquidation(LIQUIDATION_ROUTER);
        liquidationRouter.swapExactAmountOut(
            _liquidationPair, address(this), _amountOut, _amountInMax, block.timestamp + 1 minutes
        );

       // Get the max redeemable shares for this contract from the vault
       IVault vault = IVault(_vaultAddress);
       uint256 maxRedeemableShares = vault.maxRedeem(address(this));

       // Redeem the max redeemable shares from the vault
       vault.redeem(maxRedeemableShares, address(this), address(this));

        // Swap back to prize token or any other token as required using 1inch
        _executeSwap(swapBackData);
    }


    function outAndBack(
        address _liquidationPair,
        uint256 _amountOut,
        uint256 _amountInMax,
        bytes calldata swapBackData
    ) external onlyOwner {
        ILiquidation liquidationRouter = ILiquidation(LIQUIDATION_ROUTER);
        liquidationRouter.swapExactAmountOut(
            _liquidationPair, address(this), _amountOut, _amountInMax, block.timestamp + 1 minutes
        );

        // Swap back to prize token or any other token as required using 1inch
        _executeSwap(swapBackData);
    }

    function _executeSwap(bytes calldata swapData) internal {
        (bool success, ) = ONEINCH_ROUTER.call(swapData);
        require(success, "1inch-swap-failed");
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "Transfer failed");
    }
}