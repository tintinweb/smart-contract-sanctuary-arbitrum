/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Multisend {
    constructor() public {}

    receive() external payable {}

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Multisend: transferFrom failed"
        );
    }

    function _safeTransferETH(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "Multisend: ETH transfer failed");
    }

    function linearMultisend(
        address _token,
        uint256 _totalAmount,
        address[] memory _receivers
    ) external {
        uint256 length = _receivers.length;
        uint256 amount = _totalAmount / length;
        for (uint256 i = 0; i < length; i++) {
            _safeTransferFrom(_token, msg.sender, _receivers[i], amount);
        }
    }

    function linearMultisendETH(address[] memory _receivers) external payable {
        uint256 length = _receivers.length;
        uint256 amount = msg.value / length;
        for (uint256 i = 0; i < length; i++) {
            _safeTransferETH(_receivers[i], amount);
        }
    }

    function multisend(
        address _token,
        uint256[] memory _amounts,
        address[] memory _receivers
    ) external {
        uint256 length = _receivers.length;
        require(_amounts.length == length, "Multisend: BAD_LENGTHS");
        for (uint256 i = 0; i < length; i++) {
            _safeTransferFrom(_token, msg.sender, _receivers[i], _amounts[i]);
        }
    }

    function multisendETH(
        uint256[] memory _amounts,
        address[] memory _receivers
    ) external payable {
        uint256 length = _receivers.length;
        require(_amounts.length == length, "Multisend: BAD_LENGTHS");
        for (uint256 i = 0; i < length; i++) {
            _safeTransferETH(_receivers[i], _amounts[i]);
        }
    }
}