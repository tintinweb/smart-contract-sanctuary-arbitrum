// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract BaseV2FeesInterface {
    function claimFeesFor(
        address recipient,
        uint256 amount0,
        uint256 amount1
    ) external {}

    function factoryAddress() external view returns (address _factory) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(address _token0, address _token1) external {}
}