// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./IERC165.sol";

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenID,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IIdentity {
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    event ModuleManagerSwitched(
        address indexed oldModuleManager,
        address indexed newModuleManager
    );

    event Executed(
        address indexed module,
        address indexed to,
        uint256 value,
        bytes data
    );

    function owner() external view returns (address);

    function setOwner(address newOwner) external;

    function moduleManager() external view returns (address);

    function setModuleManager(address newModuleManager) external;

    function isModuleEnabled(address module) external view returns (bool);

    function getDelegate(bytes4 methodID) external view returns (address);

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);
}

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "../../interface/IERC165.sol";
import "../../interface/IERC721Receiver.sol";
import "../../interface/IERC1155Receiver.sol";
import "../../interface/IERC1271.sol";
import "../../interface/IIdentity.sol";
import "../../utils/ECDSA.sol";

contract DelegateModule is
    IERC165,
    IERC721Receiver,
    IERC1155Receiver,
    IERC1271
{
    using ECDSA for bytes32;

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IERC721Receiver).interfaceId ||
            interfaceID == type(IERC1155Receiver).interfaceId ||
            interfaceID == type(IERC1271).interfaceId;
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenID */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        require(signature.length == 65, "DM: invalid signature length");

        address signer = hash.recover(signature);

        require(signer == IIdentity(msg.sender).owner(), "DM: invalid signer");

        return IERC1271.isValidSignature.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library ECDSA {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // ref. https://ethereum.github.io/yellowpaper/paper.pdf (301) (302)
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid s value in signature"
        );
        require(v == 27 || v == 28, "ECDSA: invalid v value in signature");

        address signer = ecrecover(hash, v, r, s);

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        require(sig.length == 65, "ECDSA: invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes memory sig,
        uint256 index
    ) internal pure returns (address) {
        require(sig.length % 65 == 0, "ECDSA: invalid signature length");
        require(index < sig.length / 65, "ECDSA: invalid signature index");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(add(sig, 0x20), mul(0x41, index)))
            s := mload(add(add(sig, 0x40), mul(0x41, index)))
            v := byte(0, mload(add(add(sig, 0x60), mul(0x41, index))))
        }

        return recover(hash, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}