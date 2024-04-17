/**
 *Submitted for verification at Arbiscan.io on 2024-04-16
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface GemJoinLike {
    function dec() external view returns (uint256);
    function gem() external view returns (TokenLike);
    function exit(address, uint256) external;
}

interface ZarJoinLike {
    function zar() external view returns (TokenLike);
    function join(address, uint256) external;
}

interface TokenLike {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface CharterManagerLike {
    function exit(address crop, address usr, uint256 val) external;
}

interface UniV3RouterLike {

    struct ExactInputParams {
        bytes   path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(UniV3RouterLike.ExactInputParams calldata params) external payable returns (uint256 amountOut);
}


contract UniswapV3Callee {
    UniV3RouterLike         public uniV3Router;
    ZarJoinLike             public zarJoin;
    TokenLike               public zar;

    uint256                 public constant RAY = 10 ** 27;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function _divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _add(x, _sub(y, 1)) / y;
    }

    constructor(address uniV3Router_, address zarJoin_) public {
        uniV3Router = UniV3RouterLike(uniV3Router_);
        zarJoin = ZarJoinLike(zarJoin_);
        zar = zarJoin.zar();

        zar.approve(zarJoin_, uint256(-1));
    }

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (_sub(18, GemJoinLike(gemJoin).dec()));
    }

    function clipperCall(
        address sender,            // Clipper caller, pays back the loan
        uint256 owe,               // Zar amount to pay back        [rad]
        uint256 slice,             // Gem amount received           [wad]
        bytes calldata data        // Extra data, see below
    ) external {
        (
        address to,            // address to send remaining Zar to
        address gemJoin,       // gemJoin adapter address
        uint256 minProfit,     // minimum profit in Zar to make [wad]
        bytes memory path,     // packed encoding of (address, fee, address [, fee, address…])
        address charterManager // pass address(0) if no manager
        ) = abi.decode(data, (address, address, uint256, bytes, address));

        // Convert slice to token precision
        slice = _fromWad(gemJoin, slice);

        // Exit gem to token
        if(charterManager != address(0)) {
            CharterManagerLike(charterManager).exit(gemJoin, address(this), slice);
        } else {
            GemJoinLike(gemJoin).exit(address(this), slice);
        }

        // Approve uniV3 to take gem
        TokenLike gem = GemJoinLike(gemJoin).gem();
        gem.approve(address(uniV3Router), slice);

        // Calculate amount of Zar to Join (as erc20 WAD value)
        uint256 zarToJoin = _divup(owe, RAY);

        // Do operation and get zar amount bought (checking the profit is achieved)
        UniV3RouterLike.ExactInputParams memory params = UniV3RouterLike.ExactInputParams({
        path:             path,
        recipient:        address(this),
        deadline:         block.timestamp,
        amountIn:         slice,
        amountOutMinimum: _add(zarToJoin, minProfit)
        });
        uniV3Router.exactInput(params);

        // Although Uniswap will accept all gems, this check is a sanity check, just in case
        // Transfer any lingering gem to specified address
        if (gem.balanceOf(address(this)) > 0) {
            gem.transfer(to, gem.balanceOf(address(this)));
        }

        // Convert ZAR bought to internal vat value of the msg.sender of Clipper.take
        zarJoin.join(sender, zarToJoin);

        // Transfer remaining ZAR to specified address
        zar.transfer(to, zar.balanceOf(address(this)));
    }
}