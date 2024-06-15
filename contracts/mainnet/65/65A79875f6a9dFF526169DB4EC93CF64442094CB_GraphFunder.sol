// SPDX-License-Identifier: GPLv3
pragma solidity ~0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IBilling {
    function addTo(address _to, uint256 _amount) external;
}

contract GraphFunder {
    error SwapFailed();
    error InvalidToken();
    error Unauthorized();

    address public owner;
    address public immutable zeroEx = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    address public immutable spokePool = 0xe35e9842fceaCA96570B734083f4a58e8F7C5f2A;
    IERC20 public immutable weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 public immutable graphToken = IERC20(0x9623063377AD1B27544C965cCd7342f7EA7e88C7);
    IBilling public immutable graphBilling = IBilling(0x1B07D3344188908Fb6DEcEac381f3eE63C48477a);

    constructor() {
        owner = msg.sender;
        weth.approve(zeroEx, type(uint256).max);
        graphToken.approve(address(graphBilling), type(uint256).max);
    }

    function handleV3AcrossMessage(
        address tokenSent,
        uint256 amount,
        address relayer,
        bytes memory message
    ) external {
        if (msg.sender != spokePool) revert Unauthorized();
        if (tokenSent != address(weth)) revert InvalidToken();

        // Swap WETH for GRT
        // TODO: Get a quote and swap on-demand using Uniswap's UniversalRouter
        (bytes memory swapCalldata, address fundee) = abi.decode(message, (bytes, address));
        (bool success,) = zeroEx.call{value: amount}(swapCalldata);

        if (!success) revert SwapFailed();

        // Add GRT to the fundee's balance
        graphBilling.addTo(fundee, IERC20(tokenSent).balanceOf(address(this)));
    }

    function withdrawEth() public {
        if (msg.sender != owner) revert Unauthorized();

        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _token) public {
        if (msg.sender != owner) revert Unauthorized();

        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(msg.sender));
    }

    receive() external payable {}
}