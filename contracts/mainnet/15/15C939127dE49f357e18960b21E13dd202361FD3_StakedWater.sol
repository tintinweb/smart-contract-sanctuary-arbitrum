// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC4626, ERC20} from "./ERC4626.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";

//Temporary staker to encourage lock up and rewards distribution
contract StakedWater is ERC4626 {
    constructor(ERC20 token_) ERC4626(token_, "Staked Water", "sWater") {}

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        super.beforeWithdraw(assets, shares);
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        super.afterDeposit(assets, shares);
    }
}