// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== UniV3Asset.sol ============================
// ====================================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "./Stabilizer.sol";
import "./IERC721Receiver.sol";
import "./LiquidityHelper.sol";
import "./INonfungiblePositionManager.sol";

contract UniV3Asset is IERC721Receiver, Stabilizer {
    // Variables
    uint256 public tokenId;
    address public token0;
    address public token1;
    uint128 public liquidity;
    uint24 public constant poolFee = 3000; // Fees are 500(0.05%), 3000(0.3%), 10000(1%)
    int24 public constant tickSpacing = 60; // TickSpacings are 10, 60, 200
    bool private immutable flag; // The sort status of tokens

    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    LiquidityHelper private immutable liquidityHelper;

    // Events
    event Mint(uint256 tokenId, uint128 liquidity);
    event Collected(uint256 amount0, uint256 amount1);

    // Errors
    error NotMinted();
    error AlreadyMinted();
    error InvalidTokenID();

    /* ========== Modifies ========== */

    modifier isMinted() {
        if (tokenId == 0) revert NotMinted();
        _;
    }

    constructor(
        address _sweep_address,
        address _usdx_address,
        address _liquidityHelper,
        address _amm_address,
        address _borrower
    ) Stabilizer(_sweep_address, _usdx_address, _amm_address, _borrower) {
        flag = _usdx_address < _sweep_address;

        (token0, token1) = flag
            ? (_usdx_address, _sweep_address)
            : (_sweep_address, _usdx_address);

        liquidityHelper = LiquidityHelper(_liquidityHelper);
    }

    /* ========== Views ========== */

    /**
     * @notice Current Value of investment.
     * @return total with 6 decimal to be compatible with dollar coins.
     */
    function currentValue() public view override returns (uint256) {
        return assetValue() + super.currentValue();
    }

    /**
     * @notice Gets the asset price of AMM
     * @return the amm usdx amount
     */
    function assetValue() public view returns (uint256) {
        if (tokenId == 0) return 0;

        (uint256 _amount0, uint256 _amount1) = liquidityHelper
            .getTokenAmountsFromLP(tokenId, token0, token1, poolFee);

        (uint256 _usdx_amount, uint256 _sweep_amount) = flag
            ? (_amount0, _amount1)
            : (_amount1, _amount0);

        return _usdx_amount + sweep.convertToUSDX(_sweep_amount);
    }

    /* ========== Actions ========== */

    /**
     * @notice Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (tokenId > 0) revert AlreadyMinted();
        _createDeposit(_tokenId);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Increases liquidity in the current range
     * @dev Pool must be initialized already to add liquidity
     * @param _usdx_amount USDX Amount of asset to be deposited
     * @param _sweep_amount Sweep Amount of asset to be deposited
     */
    function invest(uint256 _usdx_amount, uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
        validAmount(_sweep_amount)
    {
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);
        _sweep_amount = _min(_sweep_amount, sweep_balance);

        TransferHelper.safeApprove(
            address(usdx),
            address(nonfungiblePositionManager),
            _usdx_amount
        );

        TransferHelper.safeApprove(
            address(sweep),
            address(nonfungiblePositionManager),
            _sweep_amount
        );

        uint128 _liquidity;
        uint256 _amount0;
        uint256 _amount1;
        (uint256 amountAdd0, uint256 amountAdd1) = flag
            ? (_usdx_amount, _sweep_amount)
            : (_sweep_amount, _usdx_amount);

        if (tokenId == 0) {
            (, _liquidity, _amount0, _amount1) = _mint(amountAdd0, amountAdd1);
        } else {
            (_liquidity, _amount0, _amount1) = nonfungiblePositionManager
                .increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId: tokenId,
                        amount0Desired: amountAdd0,
                        amount1Desired: amountAdd1,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp + 60 // Expiration: 1 hour from now
                    })
                );
            liquidity += _liquidity;
        }

        _logAction();

        if (flag) emit Invested(_amount0, _amount1);
        else emit Invested(_amount1, _amount0);
    }

    /**
     * @notice A function that decreases the current liquidity.
     * @param _liquidity_amount Liquidity Amount to decrease
     */
    function divest(uint256 _liquidity_amount)
        public
        override
        onlyBorrowerOrBalancer
        isMinted
        validAmount(_liquidity_amount)
    {
        uint128 decreaseLP = uint128(_liquidity_amount);
        if (decreaseLP > liquidity) decreaseLP = liquidity;
        liquidity -= decreaseLP;

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: decreaseLP,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        (uint256 amount0, uint256 amount1) = collect();

        _logAction();

        if (flag) emit Divested(amount0, amount1);
        else emit Divested(amount1, amount0);
    }

    /**
     * @notice Collects the fees associated with provided liquidity
     * @dev The contract must hold the erc721 token before it can collect fees
     */
    function collect()
        public
        onlyBorrower
        notFrozen
        isMinted
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        emit Collected(amount0, amount1);
    }

    /**
     * @notice Transfers the NFT to the owner
     */
    function retrieveNFT() external onlyAdmin isMinted {
        // transfer ownership to original owner
        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        tokenId = 0;
    }

    /**
     * @notice Get the ticks which will be used in the creating LP
     * @return minTick The minimum tick
     * @return maxTick The maximum tick
     */
    function showTicks() internal view returns (int24 minTick, int24 maxTick) {
        uint256 sweepPrice = sweep.target_price();
        uint256 minPrice = (sweepPrice * 99) / 100;
        uint256 maxPrice = (sweepPrice * 101) / 100;

        minTick = liquidityHelper.getTickFromPrice(
            minPrice,
            sweep.decimals(),
            tickSpacing,
            flag
        );

        maxTick = liquidityHelper.getTickFromPrice(
            maxPrice,
            sweep.decimals(),
            tickSpacing,
            flag
        );

        (minTick, maxTick) = minTick < maxTick
            ? (minTick, maxTick)
            : (maxTick, minTick);
    }

    function _createDeposit(uint256 _tokenId) internal {
        (
            ,
            ,
            address _token0,
            address _token1,
            ,
            ,
            ,
            uint128 _liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);

        if (token0 != _token0 || token1 != _token1) revert InvalidTokenID();

        liquidity = _liquidity;
        tokenId = _tokenId;

        emit Mint(_tokenId, _liquidity);
    }

    /**
     * @notice Calls the mint function defined in periphery, mints the same amount of each token.
     * For this example we are providing 1000 USDX and 1000 address(SWEEP) in liquidity
     * @dev Pool must be initialized already to add liquidity
     * @param amount0ToMint Amount of USDX
     * @param amount1ToMint Amount of SWEEP
     * @return _tokenId The id of the newly minted ERC721
     * @return _liquidity The amount of liquidity for the position
     * @return _amount0 The amount of token0
     * @return _amount1 The amount of token1
     */
    function _mint(uint256 amount0ToMint, uint256 amount1ToMint)
        internal
        returns (
            uint256 _tokenId,
            uint128 _liquidity,
            uint256 _amount0,
            uint256 _amount1
        )
    {
        (int24 minTick, int24 maxTick) = showTicks();

        (_tokenId, _liquidity, _amount0, _amount1) = nonfungiblePositionManager
            .mint(
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: poolFee,
                    tickLower: minTick,
                    tickUpper: maxTick,
                    amount0Desired: amount0ToMint,
                    amount1Desired: amount1ToMint,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp
                })
            );

        // Create a deposit
        _createDeposit(_tokenId);
    }
}