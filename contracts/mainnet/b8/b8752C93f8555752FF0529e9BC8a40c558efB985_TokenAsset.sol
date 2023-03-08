// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ========================== TokenAsset.sol ==========================
// ====================================================================

/**
 * @title Token Asset
 * @author MAXOS Team - https://maxos.finance/
 */
import "./Stabilizer.sol";
import "./AggregatorV3Interface.sol";

contract TokenAsset is Stabilizer {
    // Tokens
    IERC20Metadata public token;

    // oracle to fetch price token / base
    AggregatorV3Interface private immutable oracle;

    constructor(
        address _sweep_address,
        address _usdx_address,
        address _token_address,
        address _oracle_address,
        address _amm_address,
        address _borrower
    ) Stabilizer(_sweep_address, _usdx_address, _amm_address, _borrower) {
        token = IERC20Metadata(_token_address);
        oracle = AggregatorV3Interface(_oracle_address);
    }

    /* ========== Views ========== */

    function name() external view returns (string memory) {
        return token.name();
    }

    /**
     * @notice Current Value of investment.
     * @return total with 6 decimal to be compatible with dollar coins.
     */
    function currentValue() public view override returns (uint256) {
        return assetValue() + super.currentValue();
    }

    /**
     * @notice Asset Value of investment.
     * @return the Returns the value of the investment in the USD coin
     * @dev the price is obtained from Chainlink
     */
    function assetValue() public view returns (uint256) {
        uint256 token_balance = token.balanceOf(address(this));
        (, int256 price, , , ) = oracle.latestRoundData();

        uint256 usdx_amount = (token_balance *
            uint256(price) *
            10**usdx.decimals()) / (10**(token.decimals() + oracle.decimals()));

        return usdx_amount;
    }

    /* ========== Actions ========== */

    /**
     * @notice Function to swap from usdx to token.
     * @param _usdx_amount Amount of usdx to be swapped for token.
     */
    function invest(uint256 _usdx_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
    {
        (uint256 usdx_balance, ) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);

        TransferHelper.safeApprove(address(usdx), address(amm), _usdx_amount);
        amm.swapExactInput(
            address(usdx),
            address(token),
            _usdx_amount,
            0
        );

        _logAction();
        emit Invested(_usdx_amount, 0);
    }

    /**
     * @notice Divest.
     * @param _usdx_amount Amount to be divested.
     */
    function divest(uint256 _usdx_amount)
        public
        override
        onlyBorrowerOrBalancer
        validAmount(_usdx_amount)
    {
        (, int256 price, , , ) = oracle.latestRoundData();
        uint256 token_amount = (_usdx_amount *
            (10**(token.decimals() + oracle.decimals()))) /
            (uint256(price) * 10**usdx.decimals());

        uint256 token_balance = token.balanceOf(address(this));
        token_amount = _min(token_amount, token_balance);

        TransferHelper.safeApprove(address(token), address(amm), token_amount);
        uint256 usdx_amount = amm.swapExactInput(
            address(token),
            address(usdx),
            token_amount,
            0
        );

        _logAction();
        emit Divested(usdx_amount, 0);
    }

    /**
     * @notice Liquidate
     */
    function liquidate() external {
        _liquidate(address(token));
    }
}