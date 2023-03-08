// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== AaveV3Asset.sol ==========================
// ====================================================================
// Intergrated with Aave V3

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "./Stabilizer.sol";
import "./IAaveV3Pool.sol";

contract AaveV3Asset is Stabilizer {
    // Tokens
    IERC20 private aaveUSDX_Token;

    // Pools
    IPool private aaveV3_Pool;

    constructor(
        address _sweep_address,
        address _usdx_address,
        address _aave_usdx_address,
        address _aaveV3_pool_address,
        address _amm_address,
        address _borrower
    ) Stabilizer(_sweep_address, _usdx_address, _amm_address, _borrower) {
        aaveUSDX_Token = IERC20(_aave_usdx_address); //aaveUSDC
        aaveV3_Pool = IPool(_aaveV3_pool_address);
    }

    /* ========== Views ========== */

    /**
     * @notice Get Current Value
     * @return uint256.
     */
    function currentValue() public view override returns (uint256) {
        return assetValue() + super.currentValue();
    }

    /**
     * @notice Gets the current value in USDX of this OnChainAsset
     * @return the current usdx amount
     */
    function assetValue() public view returns (uint256) {
        // All numbers given are in USDX unless otherwise stated
        return aaveUSDX_Token.balanceOf(address(this));
    }

    /* ========== Actions ========== */

    /**
     * @notice Invest USDX
     * @param _usdx_amount USDX Amount to be invested.
     */
    function invest(uint256 _usdx_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
    {
        (uint256 usdx_balance, ) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);

        TransferHelper.safeApprove(
            address(usdx),
            address(aaveV3_Pool),
            _usdx_amount
        );
        aaveV3_Pool.supply(address(usdx), _usdx_amount, address(this), 0);

        _logAction();
        emit Invested(_usdx_amount, 0);
    }

    /**
     * @notice Divests From AaveV3.
     * Sends balance from the AaveV3 to the Asset.
     * @param _usdx_amount Amount to be divested.
     */
    function divest(uint256 _usdx_amount)
        public
        override
        onlyBorrowerOrBalancer
        validAmount(_usdx_amount)
    {
        if (aaveUSDX_Token.balanceOf(address(this)) < _usdx_amount)
            _usdx_amount = type(uint256).max;

        aaveV3_Pool.withdraw(address(usdx), _usdx_amount, address(this));

        _logAction();
        emit Divested(_usdx_amount, 0);
    }

    /**
     * @notice liquidate
     */
    function liquidate() external {
        _liquidate(address(aaveUSDX_Token));
    }

}