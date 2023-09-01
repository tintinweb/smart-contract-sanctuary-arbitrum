// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC2981Internal } from './IERC2981Internal.sol';

/**
 * @title ERC2981 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC2981Internal, IERC165 {
    /**
     * @notice called with the sale price to determine how much royalty is owed and to whom
     * @param tokenId the ERC721 or ERC1155 token id to query for royalty information
     * @param salePrice the sale price of the given asset
     * @return receiever rightful recipient of royalty
     * @return royaltyAmount amount of royalty owed
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiever, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC2981 interface
 */
interface IERC2981Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public virtual view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view virtual returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(
        bytes4 interfaceId,
        bool status
    ) internal virtual {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Base } from './base/IERC1155Base.sol';
import { IERC1155Enumerable } from './enumerable/IERC1155Enumerable.sol';
import { IERC1155Metadata } from './metadata/IERC1155Metadata.sol';

interface ISolidStateERC1155 is
    IERC1155Base,
    IERC1155Enumerable,
    IERC1155Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC165Base } from '../../introspection/ERC165/base/ERC165Base.sol';
import { ERC1155Base, ERC1155BaseInternal } from './base/ERC1155Base.sol';
import { ERC1155Enumerable } from './enumerable/ERC1155Enumerable.sol';
import { ERC1155EnumerableInternal } from './enumerable/ERC1155EnumerableInternal.sol';
import { ERC1155Metadata } from './metadata/ERC1155Metadata.sol';
import { ISolidStateERC1155 } from './ISolidStateERC1155.sol';

/**
 * @title SolidState ERC1155 implementation
 */
abstract contract SolidStateERC1155 is
    ISolidStateERC1155,
    ERC1155Base,
    ERC1155Enumerable,
    ERC1155Metadata,
    ERC165Base
{
    /**
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 * @dev inheritor must either implement ERC165 supportsInterface or inherit ERC165Base
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length)
            revert ERC1155Base__ArrayLengthMismatch();

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (accounts[i] == address(0))
                    revert ERC1155Base__BalanceQueryZeroAddress();
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155BaseInternal, IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(
        uint256 id
    ) public view virtual returns (address[] memory) {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(
        address account
    ) public view virtual returns (uint256[] memory) {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(
        uint256 id
    ) internal view virtual returns (address[] memory) {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(
        address account
    ) internal view virtual returns (uint256[] memory) {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155BaseInternal } from '../base/IERC1155BaseInternal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155BaseInternal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import './lib/LibDiamond.sol';

contract UsingDiamondOwner {
    modifier onlyOwner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.contractOwner,
            'Only owner is allowed to perform this action'
        );
        _;
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

import {IERC2981} from '@solidstate/contracts/interfaces/IERC2981.sol';
import {UintUtils} from '@solidstate/contracts/utils/UintUtils.sol';
import {SolidStateERC1155} from '@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol';
import {ERC1155MetadataStorage} from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol';
import {ERC1155Metadata} from '@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol';
import {IERC1155Metadata} from '@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol';
import {WithStorage, WithModifiers, TokensConstants} from '../lib/LibAppStorage.sol';
import {IERC721} from '@solidstate/contracts/interfaces/IERC721.sol';
import {IGen0Contract} from '../interfaces/IGen0.sol';
import '../lib/LibPrices.sol';
import {LibAccessControl} from '../lib/LibAccessControl.sol';
import {LibToken} from '../lib/LibToken.sol';
import {IERC165} from '@solidstate/contracts/interfaces/IERC165.sol';

import {IERC1155} from '@solidstate/contracts/interfaces/IERC1155.sol';
import {ERC1155Base} from '@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol';
import {ERC165Base} from '@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol';
import {LibDiamond} from '../lib/LibDiamond.sol';
import {LibMeta} from '../lib/LibMeta.sol';
import {PaymentType} from '../interfaces/IPayments.sol';
import {console} from 'hardhat/console.sol';
import {IPaymentsReceiver} from '../interfaces/IPaymentsReceiver.sol';

contract KaijuFacet is SolidStateERC1155, IERC2981, WithStorage, WithModifiers {
    using UintUtils for uint256;

    string public name = 'Kaiju Cards Pioneer Kaiju NFTs';

    event Unlocked(uint256 tokenId);
    event Locked(uint256 tokenId);
    event PioneerPackPurchased(
        address indexed owner,
        uint256[] indexed tokenId,
        LibToken.PioneerPackType indexed packType
    );

    function contractURI() public view returns (string memory) {
        return _constants().contractUri; // metadata for the contract itself (eg. to display in Opensea's collection page)
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override pausable {
        // console.log('SOLIDITY: _beforeTokenTransfer');
        if (from != address(0)) {
            // console.log('from is not address(0)');
            require(
                _token().pioneerTradingIsEnabled,
                'Trading for Pioneer Kaijus is currently disabled'
            );
        }

        for (uint256 i; i < ids.length; i++) {
            // console.log(
            //     'SOLIDITY: _beforeTokenTransfer loop for ids[i]',
            //     ids[i]
            // );
            if (from != address(0)) {
                require(
                    _token().isTokenTradable[ids[i]],
                    'Token locked for trading'
                );
            } else {
                _token().isTokenTradable[i] = _token().pioneerTradingIsEnabled; // TODO: change to check for NFT collection
                _token().numTradesSinceTransmog[i] = 0;
            }

            // this should reset to 0 when transmogged
            bool tokenReachedTransmogTradeLimit = _token()
                .numTradesSinceTransmog[i] >=
                _constants().NUM_TRADES_ALLOWED_AFTER_TRANSMOG;

            if (tokenReachedTransmogTradeLimit == true) {
                revert('Token reached transmog limit');
            } else {
                _token().numTradesSinceTransmog[i]++;
            }

            _token().ownerOf[ids[i]] = to;
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (
            _token().royaltiesRecipient,
            (salePrice * _token().royaltiesPercentage) / 100
        );
    }

    // TODO
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165Base, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId ||
            interfaceId == 0xd9b67a26 ||
            interfaceId == type(IPaymentsReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override(ERC1155Base, IERC1155) returns (bool) {
        //TODO

        /** @dev Standard ERC1155 approvals. */
        return super.isApprovedForAll(account, operator);
    }

    //TODO delete
    function purchaseGen1Kaiju(
        LibToken.PioneerPackType packType
    ) external payable pausable {
        require(_shop().gen1KaijuSaleOpen, 'Purchase disabled at this time');
        uint256 cost = getPioneerPackCost(packType);
        require(msg.value >= cost, 'Not enough funds sent');

        uint256 amount = getPackAmount(packType);

        uint256[] memory purchasedCharacterIds = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint8 i = 0; i < amount; i++) {
            purchasedCharacterIds[i] = _generateNftTokenId();
            amounts[i] = 1;
        }

        _safeMintBatch(msg.sender, purchasedCharacterIds, amounts, '');

        emit PioneerPackPurchased(msg.sender, purchasedCharacterIds, packType);
    }

    function _purchasePioneerKaiju(
        LibToken.PioneerPackType packType,
        address _payor,
        uint256 _paymentAmountInUSD,
        uint256 _paymentAmountInToken,
        PaymentType _paymentType
    ) internal {
        if (
            _paymentType == PaymentType.ETH_IN_USD &&
            msg.value != _paymentAmountInToken
        ) {
            revert LibMeta.IncorrectPaymentAmount(
                msg.value,
                _paymentAmountInToken
            );
        }

        LibToken.PioneerPackType expectedPackType = _constants()
            .usdPriceToPackType[_paymentAmountInUSD];

        if (packType != expectedPackType) {
            revert LibMeta.IncorrectPaymentAmount(
                uint256(packType),
                _paymentAmountInToken
            );
        }
        require(_shop().gen1KaijuSaleOpen, 'Purchase disabled at this time');
        uint256 amount = getPackAmount(packType);
        // console.log('pack amount: ', amount);

        uint256[] memory purchasedCharacterIds = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = _generateNftTokenId();
            purchasedCharacterIds[i] = tokenId;
            // console.log('MINTED tokenID: ', tokenId);
            amounts[i] = 1;
        }

        _safeMintBatch(_payor, purchasedCharacterIds, amounts, '');

        emit PioneerPackPurchased(_payor, purchasedCharacterIds, packType);
    }

    //TODO: add admin fn to mint free kaiju with voucher

    function _generateNftTokenId() internal returns (uint256) {
        return _token().pioneerKaijuIndex++;
    }

    function getPioneerPackCost(
        LibToken.PioneerPackType packType
    ) public view returns (uint256) {
        return 500000000; // TODO
    }

    function getPackAmount(
        LibToken.PioneerPackType packType
    ) public view returns (uint8) {
        return _shop().packQuantities[packType];
    }

    function beginPioneerKaijuSale() public ownerOnly {
        _shop().gen1KaijuSaleOpen = true;
    }

    function pausePioneerKaijuSale() public ownerOnly {
        _shop().gen1KaijuSaleOpen = false;
    }

    function lockNft(uint256 id) public pausable {
        require(balanceOf(msg.sender, id) != 0, 'Does not own token');
        require(_token().isTokenTradable[id], 'Already locked');
        _token().isTokenTradable[id] = false;
        emit Locked(id);
    }

    //TODO make only owner or admin?
    function unlockNft(uint256 id) public pausable {
        require(balanceOf(msg.sender, id) != 0, 'Does not own token');
        require(
            _token().pioneerTradingIsEnabled,
            'Trading for Pioneer Kaijus is currently disabled'
        );
        require(!_token().isTokenTradable[id], 'Already unlocked');
        _token().isTokenTradable[id] = true;
        emit Unlocked(id);
    }

    function isLocked(uint256 id) external view returns (bool) {
        return !_token().isTokenTradable[id];
    }

    function getOwnerOf(uint256 id) external view returns (address) {
        return _token().ownerOf[id];
    }

    function setContractUri(string memory contractUri) public ownerOnly {
        _constants().contractUri = contractUri;
    }

    function setBaseUri(string memory baseUri) public ownerOnly {
        _constants().baseUri = baseUri;
    }

    function setNumTradesAllowedAfterTransmog(
        uint8 numTrades
    ) public ownerOnly {
        _constants().NUM_TRADES_ALLOWED_AFTER_TRANSMOG = numTrades;
    }

    function getNumTradesAllowedAfterTransmog() public view returns (uint8) {
        return _constants().NUM_TRADES_ALLOWED_AFTER_TRANSMOG;
    }

    function setPioneerTradingIsEnabled(bool enabled) public ownerOnly {
        _token().pioneerTradingIsEnabled = enabled;
    }

    function getPioneerTradingIsEnabled() public view returns (bool) {
        return _token().pioneerTradingIsEnabled;
    }

    function getPioneerSaleIsOpen() public view returns (bool) {
        return _shop().gen1KaijuSaleOpen;
    }

    // get contract owner function
    function getContractOwner() public view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.contractOwner;
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        override(ERC1155Metadata, IERC1155Metadata)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _constants().baseUri,
                    tokenId.toString(),
                    '.json'
                )
            );
    }

    function setGen0ClaimingEnabled(bool enabled) public ownerOnly {
        _token().gen0ClaimingIsEnabled = enabled;
    }

    function claimFreeKaiju(uint256 tokenId) public pausable {
        bool claimingIsEnabled = _token().gen0ClaimingIsEnabled;
        require(
            claimingIsEnabled,
            'Claiming free kaiju is not currently available.'
        );

        bool ownsGen0Token = isGen0TokenOwnedBySender(tokenId);
        require(ownsGen0Token, 'You do not own this Gen0 Token!');

        bool hasClaimed = _token().hasClaimedFreeKaiju[tokenId];
        require(!hasClaimed, 'You have already claimed this free Kaiju!');

        bool tokenIsStaked = isGen0TokenStaked(tokenId);
        require(
            tokenIsStaked,
            'Your Kaiju must be staked first in order to claim.'
        );

        _token().hasClaimedFreeKaiju[tokenId] = true;
        uint256 freeKaijuId = _generateNftTokenId();
        _safeMint(msg.sender, freeKaijuId, 1, '');
    }

    function claimFreeKaijuBatch(uint256[] memory tokenIds) public pausable {
        bool claimingIsEnabled = _token().gen0ClaimingIsEnabled;
        require(
            claimingIsEnabled,
            'Claiming free kaiju is no longer available.'
        );

        uint256[] memory freeKaijuIds = new uint256[](tokenIds.length);
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            bool ownsGen0Token = isGen0TokenOwnedBySender(tokenId);
            require(ownsGen0Token, 'You do not own this Gen0 Token.');
            bool hasClaimed = _token().hasClaimedFreeKaiju[tokenId];
            require(
                !hasClaimed,
                'You have already claimed the free Kaiju for this Gen0.'
            );
            bool tokenIsStaked = isGen0TokenStaked(tokenId);
            require(
                tokenIsStaked,
                'Your Kaiju must be staked first in order to claim.'
            );

            _token().hasClaimedFreeKaiju[tokenId] = true;
            freeKaijuIds[i] = _generateNftTokenId();
            amounts[i] = 1;
        }

        _safeMintBatch(msg.sender, freeKaijuIds, amounts, '');
    }

    /**
     * @dev
     *  To be used by front end to check if user's gen0 have claimed free Kaiju.
     */
    function checkGen0HasClaimedFreeKaiju(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory hasClaimedById = new bool[](tokenIds.length); // will return in same order as tokenIds

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            bool hasClaimed = _token().hasClaimedFreeKaiju[tokenId];
            hasClaimedById[i] = hasClaimed;
        }
        return hasClaimedById;
    }

    function isGen0TokenOwnedBySender(
        uint256 tokenId
    ) internal view returns (bool) {
        IGen0Contract gen0 = IGen0Contract(_constants().gen0ContractAddress);
        return gen0.ownerOf(tokenId) == msg.sender;
    }

    function isGen0TokenStaked(uint256 tokenId) internal view returns (bool) {
        IGen0Contract gen0 = IGen0Contract(_constants().gen0ContractAddress);
        return gen0.isStaked(tokenId);
    }

    function setGen0ContractAddress(
        address gen0ContractAddress
    ) public ownerOnly {
        _constants().gen0ContractAddress = gen0ContractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IPaymentsReceiver, PriceType} from '../interfaces/IPaymentsReceiver.sol';
import {IPayments} from '../interfaces/IPayments.sol';
import {KaijuFacet} from './KaijuFacet.sol';
import {LibMeta} from '../lib/LibMeta.sol';
import {LibToken} from '../lib/LibToken.sol';
import {WithStorage, WithModifiers, TokensConstants} from '../lib/LibAppStorage.sol';
import {PaymentType} from '../interfaces/IPayments.sol';
import {IERC20} from '@solidstate/contracts/interfaces/IERC20.sol';
import {LibDiamond} from '../lib/LibDiamond.sol';
// import {console} from 'hardhat/console.sol';

contract KaijuFacetWithPayments is IPaymentsReceiver, KaijuFacet {
    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptERC20(
        address _payor, // payment sender
        address _paymentERC20, // address of token paid, either magic or ARB
        uint256 _paymentAmount, // amount of token sent, in absolute terms
        uint256 _paymentAmountInPricedToken, // paymentAmount (value in USD) * 10**8
        PriceType _priceType, // Always will be USD in our case
        address _pricedERC20 // won't be used in our case
    ) external onlySpellcasterPayments {
        emit PaymentReceived(
            _payor,
            _paymentERC20,
            _paymentAmount,
            _paymentAmountInPricedToken,
            _priceType,
            _pricedERC20
        );

        if (_priceType == PriceType.STATIC) {
            revert LibMeta.PaymentTypeNotAccepted('STATIC');
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            revert LibMeta.PaymentTypeNotAccepted('PRICED_IN_ERC20');
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            revert LibMeta.PaymentTypeNotAccepted('PRICED_IN_GAS_TOKEN');
        }

        if (_paymentERC20 == getMagicTokenAddress()) {
            _acceptMagicPaymentPricedInUSD(
                _payor,
                _paymentAmount,
                _paymentAmountInPricedToken
            );
        } else if (_paymentERC20 == getArbTokenAddress()) {
            _acceptArbPaymentPricedInUSD(
                _payor,
                _paymentAmount,
                _paymentAmountInPricedToken
            );
        } else {
            revert LibMeta.PaymentTypeNotAccepted('UNSUPPORTED_TOKEN');
        }
    }

    function acceptGasToken(
        address _payor, // sender
        uint256 _paymentAmount, // amount of eth sent (dynamic)
        uint256 _paymentAmountInPricedToken, // paymentAmount * decimals in USD (10**8) (enum)
        PriceType _priceType, // will always be PRICED_IN_USD
        address _pricedERC20 // won't be used in our case
    ) external payable onlySpellcasterPayments {
        // console.log('acceptGasToken');
        emit PaymentReceived(
            _payor,
            address(0),
            _paymentAmount,
            _paymentAmountInPricedToken,
            _priceType,
            _pricedERC20
        );
        if (msg.value != _paymentAmount) {
            revert LibMeta.IncorrectPaymentAmount(
                msg.value,
                _paymentAmountInPricedToken
            );
        }
        if (msg.value < _constants().minPriceByPaymentType[PaymentType.ETH_IN_USD]) {
            revert LibMeta.IncorrectPaymentAmount(
                msg.value,
                _paymentAmountInPricedToken
            );
        }

        if (_priceType == PriceType.STATIC) {
            revert LibMeta.PaymentTypeNotAccepted('STATIC');
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            revert LibMeta.PaymentTypeNotAccepted('PRICED_IN_ERC20');
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            revert LibMeta.PaymentTypeNotAccepted('PRICED_IN_GAS_TOKEN');
        } else {
            // priced in USD - good
            _acceptGasTokenPaymentPricedInUSD(
                _payor,
                _paymentAmount,
                _paymentAmountInPricedToken
            );
        }
    }

    function _acceptGasTokenPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmountInEth, // in eth
        uint256 _paymentAmountInUSD
    ) internal {
        LibToken.PioneerPackType packType = _getPackTypeFromPrice(
            _paymentAmountInUSD
        );
        _purchasePioneerKaiju(
            packType,
            _payor,
            _paymentAmountInUSD,
            _paymentAmountInEth,
            PaymentType.ETH_IN_USD
        );
    }

    function _acceptMagicPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmountInMagic, // in eth
        uint256 _paymentAmountInUSD
    ) internal {
        LibToken.PioneerPackType packType = _getPackTypeFromPrice(
            _paymentAmountInUSD
        );
        _purchasePioneerKaiju(
            packType,
            _payor,
            _paymentAmountInUSD,
            _paymentAmountInMagic,
            PaymentType.MAGIC_IN_USD
        );
    }

    function _acceptArbPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmountInArb, // in eth
        uint256 _paymentAmountInUSD
    ) internal {
        LibToken.PioneerPackType packType = _getPackTypeFromPrice(
            _paymentAmountInUSD
        );
        _purchasePioneerKaiju(
            packType,
            _payor,
            _paymentAmountInUSD,
            _paymentAmountInArb,
            PaymentType.ARB_IN_USD
        );
    }

    function _getPackTypeFromPrice(
        uint256 _priceInUSD
    ) internal view returns (LibToken.PioneerPackType packType) {
        packType = _constants().usdPriceToPackType[_priceInUSD];
        if (packType == LibToken.PioneerPackType.NONE) {
            revert LibMeta.InvalidUSDPrice(_priceInUSD);
        }
        return packType;
    }

    modifier onlySpellcasterPayments() {
        if (LibMeta._msgSender() != address(_constants().spellcasterPayments)) {
            revert LibMeta.SenderNotSpellcasterPayments(LibMeta._msgSender());
        }
        _;
    }

    function getSpellcasterAddress() external view returns (address) {
        return address(_constants().spellcasterPayments);
    }

    function setSpellcasterAddress(
        address spellcasterAddress_
    ) external ownerOnly {
        _constants().spellcasterPayments = IPayments(spellcasterAddress_);
    }

    function withdrawETH() public ownerOnly {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        payable(ds.contractOwner).transfer(address(this).balance);
    }

    function withdrawERC20(address tokenAddress, address to) public ownerOnly {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, 'No tokens to withdraw');
        token.transfer(to, balance);
    }

    function getMagicTokenAddress() public view returns (address) {
        return _constants().magicTokenAddress;
    }

    function setMagicTokenAddress(address magicTokenAddress_) public ownerOnly {
        _constants().magicTokenAddress = magicTokenAddress_;
    }

    function getArbTokenAddress() public view returns (address) {
        return _constants().arbTokenAddress;
    }

    function setArbTokenAddress(address arbTokenAddress_) public ownerOnly {
        _constants().arbTokenAddress = arbTokenAddress_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {IERC721} from '@solidstate/contracts/interfaces/IERC721.sol';

interface IGen0Contract is IERC721 {
    function isStaked(uint256 tokenId) external view returns (bool);
    function stakeNft(uint256 tokenId) external;
    function unstakeNft(uint256 tokenId) external;

    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Used to determine which calculation to use for the payment amount when taking a payment.
 *      STATIC: The payment amount is the input token without conversion.
 *      PRICED_IN_ERC20: The payment amount is priced in an ERC20 relative to the payment token.
 *      PRICED_IN_USD: The payment amount is priced in USD relative to the payment token.
 *      PRICED_IN_GAS_TOKEN: The payment amount is priced in the gas token relative to the payment token.
 */
enum PriceType {
    STATIC,
    PRICED_IN_ERC20,
    PRICED_IN_USD,
    PRICED_IN_GAS_TOKEN
}

enum PaymentType {
    ETH_IN_USD,
    MAGIC_IN_USD,
    ARB_IN_USD
}

interface IPayments {
    /**
     * @dev Emitted when a payment is made
     * @param payor The address of the sender of the payment
     * @param token The address of the token that was paid. If address(0), then it was gas token
     * @param amount The amount of the token that was paid
     * @param paymentsReceiver The address of the contract that received the payment. Supports IPaymentsReceiver
     */
    event PaymentSent(address payor, address token, uint256 amount, address paymentsReceiver);

    /**
     * @dev Make a payment in ERC20 to the recipient
     * @param _recipient The address of the recipient of the payment
     * @param _paymentERC20 The address of the ERC20 to take
     * @param _price The amount of the ERC20 to take
     */
    function makeStaticERC20Payment(address _recipient, address _paymentERC20, uint256 _price) external;

    /**
     * @dev Make a payment in gas token to the recipient.
     *      All this does is verify that the price matches the tx value
     * @param _recipient The address of the recipient of the payment
     * @param _price The amount of the gas token to take
     */
    function makeStaticGasTokenPayment(address _recipient, uint256 _price) external payable;

    /**
     * @dev Make a payment in ERC20 to the recipient priced in another token (Gas Token/USD/other ERC20)
     * @param _recipient The address of the payor to take the payment from
     * @param _paymentERC20 The address of the ERC20 to take
     * @param _paymentAmountInPricedToken The desired payment amount, priced in another token, depending on what `priceType` is
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     */
    function makeERC20PaymentByPriceType(
        address _recipient,
        address _paymentERC20,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external;

    /**
     * @dev Take payment in gas tokens (ETH, MATIC, etc.) priced in another token (USD/ERC20)
     * @param _recipient The address to send the payment to
     * @param _paymentAmountInPricedToken The desired payment amount, priced in another token, depending on what `_priceType` is
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     */
    function makeGasTokenPaymentByPriceType(
        address _recipient,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable;

    /**
     * @dev Admin-only function that initializes the ERC20 info for a given ERC20.
     *      Currently there are no price feeds for ERC20s, so those parameters are a placeholder
     * @param _paymentERC20 The ERC20 address
     * @param _decimals The number of decimals of this coin.
     * @param _pricedInGasTokenAggregator The aggregator for the gas coin (ETH, MATIC, etc.)
     * @param _usdAggregator The aggregator for USD
     * @param _pricedERC20s The ERC20s that have supported price feeds for the given ERC20
     * @param _priceFeeds The price feeds for the priced ERC20s
     */
    function initializeERC20(
        address _paymentERC20,
        uint8 _decimals,
        address _pricedInGasTokenAggregator,
        address _usdAggregator,
        address[] calldata _pricedERC20s,
        address[] calldata _priceFeeds
    ) external;

    /**
     * @dev Admin-only function that sets the price feed for a given ERC20.
     *      Currently there are no price feeds for ERC20s, so this is a placeholder
     * @param _paymentERC20 The ERC20 to set the price feed for
     * @param _pricedERC20 The ERC20 that is associated to the given price feed and `_paymentERC20`
     * @param _priceFeed The address of the price feed
     */
    function setERC20PriceFeedForERC20(address _paymentERC20, address _pricedERC20, address _priceFeed) external;

    /**
     * @dev Admin-only function that sets the price feed for the gas token for the given ERC20.
     * @param _pricedERC20 The ERC20 that is associated to the given price feed and `_paymentERC20`
     * @param _priceFeed The address of the price feed
     */
    function setERC20PriceFeedForGasToken(address _pricedERC20, address _priceFeed) external;

    /**
     * @param _paymentToken The token to convert from. If address(0), then the input is in gas tokens
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     * @return supported_ Whether or not a price feed exists for the given payment token and price type
     */
    function isValidPriceType(
        address _paymentToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view returns (bool supported_);

    /**
     * @dev Calculates the price of the input token relative to the output token
     * @param _paymentToken The token to convert from. If address(0), then the input is in gas tokens
     * @param _paymentAmountInPricedToken The desired payment amount, priced in either the `_pricedERC20`, gas token, or USD depending on `_priceType`
     *      used to calculate the output amount
     * @param _priceType The type of conversion to perform
     * @param _pricedERC20 The token to convert to. If address(0), then the output is in gas tokens or USD, depending on `_priceType`
     */
    function calculatePaymentAmountByPriceType(
        address _paymentToken,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view returns (uint256 paymentAmount_);

    /**
     * @return magicAddress_ The address of the $MAGIC contract
     */
    function getMagicAddress() external view returns (address magicAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {PriceType} from '../interfaces/IPayments.sol';

interface IPaymentsReceiver {
    /**
     * @dev Emitted when a payment is made
     * @param payor The address of the sender of the payment
     * @param paymentERC20 The address of the token that was paid. If address(0), then it was gas token
     * @param paymentAmount The amount of the token that was paid
     * @param paymentAmountInPricedToken The payment amount of the given priced token. Used to have dynamic payments based on the value relative to another token
     * @param priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is PRICED_IN_ERC20
     */
    event PaymentReceived(
        address payor,
        address paymentERC20,
        uint256 paymentAmount,
        uint256 paymentAmountInPricedToken,
        PriceType priceType,
        address pricedERC20
    );

    /**
     * @dev Accepts a payment in ERC20 tokens
     * @param _payor The address of the payor for this payment
     * @param _paymentERC20 The address of the ERC20 token that was paid
     * @param _paymentAmount The amount of the ERC20 token that was paid
     * @param _paymentAmountInPricedToken The amount of the ERC20 token that was paid in the given priced token
     *      For example, if the payment is the amount of MAGIC that equals $10 USD,
     *      then this value would be 10 * 10**8 (the number of decimals for USD)
     * @param _priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param _pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is `PriceType.PRICED_IN_ERC20`
     */
    function acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external;

    /**
     * @dev Accepts a payment in gas tokens
     * @param _payor The address of the payor for this payment
     * @param _paymentAmount The amount of the gas token that was paid
     * @param _paymentAmountInPricedToken The amount of the gas token that was paid in the given priced token
     *      For example, if the payment is the amount of ETH that equals $10 USD,
     *      then this value would be 10 * 10**8 (the number of decimals for USD)
     * @param _priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param _pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is `PriceType.PRICED_IN_ERC20`
     */
    function acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

library LibAccessControl {
    /// @notice Access Control Roles
    enum Roles {
        NULL,
        TOKEN_MANAGER,
        ADMIN,
        MINTER
    }

    enum Gen1MinterStatus {
        NULL,
        ALLOWLIST,
        TIER_1_DISCOUNT,
        TIER_2_DISCOUNT,
        GIVEAWAY
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;
import {UsingDiamondOwner} from '../UsingDiamondOwner.sol';
import {LibDiamond} from './LibDiamond.sol';

import '@solidstate/contracts/data/EnumerableSet.sol';
import {LibAccessControl} from './LibAccessControl.sol';
import {LibToken} from '../lib/LibToken.sol';
import {IPayments} from '../interfaces/IPayments.sol';
import {PaymentType} from '../interfaces/IPayments.sol';

struct TokensConstants {
    string baseUri;
    string contractUri;
    uint8 NUM_TRADES_ALLOWED_AFTER_TRANSMOG;
    address gen0ContractAddress;
    IPayments spellcasterPayments;
    address magicTokenAddress;
    address arbTokenAddress;
    mapping (uint256 => LibToken.PioneerPackType) usdPriceToPackType;
    mapping(PaymentType => uint256) minPriceByPaymentType;
}

struct ShopStorage {
    uint32 gen1KaijuPriceInUSD;
    uint32 gen1KaijuPriceInNativeToken;
    mapping(LibToken.PioneerPackType => uint8) packQuantities;
    mapping(address => uint16) gen1KaijuPurchasedByAddress;
    uint256 totalGen1KaijuPurchased;
    bool gen1KaijuSaleOpen;
}

struct PriceStorage {
    uint256 nativeTokenPriceInUsd; // check with treasure about payments module
}

// shared between all ERC1155 tokens
// TODO: write test to make sure these are not mutable by unauthorized functions
struct TokensStorage {
    mapping(uint256 => bool) isTokenTradable;
    mapping(uint256 => address) ownerOf; // is this part of ERC1155?
    mapping(uint256 => uint8) numTradesSinceTransmog; // mapping from NFT id to number of trades, starts at 0 and resets to 0 after transmog
    mapping(uint256 => LibToken.ItemType) itemTypeByTokenId; // mapping from NFT id to item type
    mapping(uint256 => bool) hasClaimedFreeKaiju; // gen0 token ID => has claimed
    bool pioneerTradingIsEnabled;
    bool equipmentMintingIsEnabled;
    bool equipmentTradingIsEnabled;
    bool lootboxMintingIsEnabled;
    bool lootboxTradingIsEnabled;
    bool gen0ClaimingIsEnabled;
    address royaltiesRecipient; // multi sig
    uint256 royaltiesPercentage; // 10%
    uint256 pioneerKaijuIndex;
    uint256 lootboxIndex;
    uint256 equipmentIndex;
}

struct PioneerKaijuStorage {
    uint256 pioneerKaijuIndex;
}

struct AccessControlStorage {
    bool paused;
    address contractFundsRecipient;
    mapping(address => EnumerableSet.UintSet) rolesByAddress;
}

library AppStorage {
    bytes32 public constant _SHOP_STORAGE_POSITION =
        keccak256('kaijucards.storage.shop');
    bytes32 public constant _PRICE_STORAGE_POSITION =
        keccak256('kaijucards.storage.price');
    bytes32 public constant _TOKENS_STORAGE_POSITION =
        keccak256('kaijucards.storage.tokens');
    bytes32 public constant _TOKENS_CONSTANTS_POSITION =
        keccak256('kaijucards.constants.tokens');
    bytes32 public constant _ACCESS_CONTROL_STORAGE_POSITION =
        keccak256('kaijucards.storage.access_control');

    function shopStorage() internal pure returns (ShopStorage storage ss) {
        bytes32 position = _SHOP_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    function priceStorage() internal pure returns (PriceStorage storage ps) {
        bytes32 position = _PRICE_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function tokensStorage() internal pure returns (TokensStorage storage ts) {
        bytes32 position = _TOKENS_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    function tokensConstants()
        internal
        pure
        returns (TokensConstants storage tc)
    {
        bytes32 position = _TOKENS_CONSTANTS_POSITION;
        assembly {
            tc.slot := position
        }
    }

    function accessControlStorage()
        internal
        pure
        returns (AccessControlStorage storage acs)
    {
        bytes32 position = _ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            acs.slot := position
        }
    }
}

contract WithStorage {
    function _shop() internal pure returns (ShopStorage storage) {
        return AppStorage.shopStorage();
    }

    function _price() internal pure returns (PriceStorage storage) {
        return AppStorage.priceStorage();
    }

    function _token() internal pure returns (TokensStorage storage) {
        return AppStorage.tokensStorage();
    }

    function _constants() internal pure returns (TokensConstants storage) {
        return AppStorage.tokensConstants();
    }

    function _access() internal pure returns (AccessControlStorage storage) {
        return AppStorage.accessControlStorage();
    }
}

contract WithModifiers is WithStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    modifier ownerOnly() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.contractOwner,
            'Only owner is allowed to perform this action'
        );
        _;
    }

    modifier internalOnly() {
        require(msg.sender == address(this), 'AppStorage: Not contract owner');
        _;
    }

    modifier roleOnly(LibAccessControl.Roles role) {
        require(
            _access().rolesByAddress[msg.sender].contains(uint256(role)) ||
                msg.sender == address(this),
            'Missing role'
        );
        _;
    }

    modifier pausable() {
        require(!_access().paused, 'Contract paused');
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

library LibMeta {
    function _msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender_ := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender_ = msg.sender;
        }
    }

    /**
     * @dev Emitted when an incorrect payment amount is provided.
     * @param amount The provided payment amount
     * @param price The expected payment amount (price)
     */
    error IncorrectPaymentAmount(uint256 amount, uint256 price);

    /**
     * @dev Emitted when an incorrect USD amount is provided.
     * @param price The provided payment amount in 8-decimal USD
     */
    error InvalidUSDPrice(uint256 price);

    /**
     * @dev Emitted when the sender is not a valid spellcaster payment address.
     * @param sender The address of the sender attempting the action
     */
    error SenderNotSpellcasterPayments(address sender);

    /**
     * @dev Emitted when a non-accepted payment type is provided.
     * @param paymentType The provided payment type
     */
    error PaymentTypeNotAccepted(string paymentType);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

library LibPrices {
    function getPerDollarTokenPrice(uint256 amount, uint256 tokenPrice)
        internal
        pure
        returns (uint256)
    {
        return ((amount * 1 ether) / uint256(tokenPrice));
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

library LibToken {
    enum PioneerPackType {
        NONE,
        SINGLE,
        HERO,
        LEGENDARY
    }

    enum ItemType {
        EQUIPMENT,
        LOOTBOX,
        ITEM
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}