// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract BaseV2MinterInterface {
    event Mint(
        address indexed sender,
        uint256 weekly,
        uint256 circulating_supply,
        uint256 circulating_emission
    );

    function _token() external view returns (address) {}

    function _ve() external view returns (address) {}

    function _ve_dist() external view returns (address) {}

    function _voter() external view returns (address) {}

    function active_period() external view returns (uint256) {}

    function calculate_emission() external view returns (uint256) {}

    function calculate_growth(uint256 _minted)
        external
        view
        returns (uint256)
    {}

    function circulating_emission() external view returns (uint256) {}

    function circulating_supply() external view returns (uint256) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialMint(
        address[] memory claimants,
        uint256[] memory amounts,
        uint256 max
    ) external {}

    function initialize(
        address __voter,
        address __ve,
        address __ve_dist
    ) external {}

    function update_period() external returns (uint256) {}

    function weekly() external view returns (uint256) {}

    function weekly_emission() external view returns (uint256) {}
}