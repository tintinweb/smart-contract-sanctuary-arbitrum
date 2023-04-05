pragma solidity ^0.8.0;
import "../interfaces/IWETH.sol";
import "../interfaces/INFTMintSale.sol";
import "../interfaces/INFTMintSaleMultiple.sol";

contract NativeTokenHelper {
    IWETH public immutable WETH;
    constructor (IWETH weth) {
        WETH = weth;
    }

    function approveSale(address sale) external {
        WETH.approve(sale, type(uint256).max);
    }

    function buyNFT(INFTMintSale sale, address recipient) external payable {
        WETH.deposit{value: msg.value}();
        sale.buyNFT(recipient);
    }

    function buyNFT(INFTMintSaleMultiple sale, address recipient, uint256 tier) external payable {
        WETH.deposit{value: msg.value}();
        sale.buyNFT(recipient, tier);
    }
    function buyMultipleNFT(INFTMintSaleMultiple sale, address recipient, uint256[] calldata tiersToBuy) external payable {
        WETH.deposit{value: msg.value}();
        sale.buyMultipleNFT(recipient, tiersToBuy);
    }

}

pragma solidity >=0.5.0;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.0;
interface INFTMintSale {

    function buyNFT(address recipient) external;
}

pragma solidity ^0.8.0;
interface INFTMintSaleMultiple {

    function buyNFT(address recipient, uint256 tier) external;
    function buyMultipleNFT(address recipient, uint256[] calldata tiersToBuy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}