// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract ChildChainSolidInterface {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Initialized(uint8 version);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256) {}

    function approve(address spender, uint256 amount) external returns (bool) {}

    function balanceOf(address account) external view returns (uint256) {}

    function decimals() external view returns (uint8) {}

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool) {}

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool) {}

    function initialize(uint256 _amount) external {}

    function mint(address _to, uint256 _amount) external {}

    function name() external view returns (string memory) {}

    function symbol() external view returns (string memory) {}

    function totalSupply() external view returns (uint256) {}

    function transfer(address to, uint256 amount) external returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {}

}