// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Tokenized ownership of Safes.
contract Safes {
    error Unauthorized();

    error CallReverted();

    event TransferSingle(
        address indexed owner, address indexed from, address indexed to, uint256 id, uint256 amount
    );

    event URI(string metadata, uint256 indexed id);

    string public constant name = "Safes";

    string public constant symbol = unicode"🗝️";

    mapping(uint256 id => string metadata) internal _uri;

    function uri(uint256 id) public view returns (string memory) {
        return _uri[id]; // Metadata.
    }

    function setURI(uint256 id, string calldata metadata) public {
        if (balanceOf(msg.sender, id) != 0) emit URI(_uri[id] = metadata, id);
        else revert Unauthorized();
    }

    function balanceOf(address owner, uint256 id) public view returns (uint256) {
        return ISafes(address(uint160(id))).isOwner(owner) ? 1 : 0;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable {
        if (balanceOf(msg.sender, id) != 0) {
            if (
                ISafes(to).onERC1155Received{value: msg.value}(msg.sender, from, id, amount, data)
                    != ISafes.onERC1155Received.selector
            ) revert CallReverted();
            emit TransferSingle(msg.sender, from, to, id, amount);
        } else {
            revert Unauthorized();
        }
    }

    function register(address account) public {
        address[] memory owners = ISafes(account).getOwners();
        uint256 id = uint256(uint160(account));
        for (uint256 i; i != owners.length; ++i) {
            emit TransferSingle(msg.sender, address(0), owners[i], id, 1);
        }
    }
}

interface ISafes {
    function isOwner(address) external view returns (bool);
    function getOwners() external view returns (address[] memory);
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        payable
        returns (bytes4);
}