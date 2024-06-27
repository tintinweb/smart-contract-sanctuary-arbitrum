// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC165.sol";

/*
 *
 * @dev Interface for the Future Rewards Token Standard.
 *
 * A standardized way to receive future rewards for non-fungible tokens (NFTs.)
 *
 */
interface InFR is IERC165 {

    event FRClaimed(address indexed account, uint256 indexed amount);

    event FRDistributed(uint256 indexed tokenId, uint256 indexed soldPrice, uint256 indexed allocatedFR);

    event Listed(uint256 indexed tokenId, uint256 indexed salePrice);

    event Unlisted(uint256 indexed tokenId);

    event Bought(uint256 indexed tokenId, uint256 indexed salePrice);

    function list(uint256 tokenId, uint256 salePrice) external;

    function unlist(uint256 tokenId) external;

    function buy(uint256 tokenId) payable external;

    function releaseFR(address payable account) external;

    function getFRInfo(uint256 tokenId) external returns(uint8, uint256, uint256, uint256, uint256, address[] memory);

    function getAllottedFR(address account) external returns(uint256);

    function getListInfo(uint256 tokenId) external returns(uint256, address, bool);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
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

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
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

pragma solidity ^0.8.8;

interface IProxy {
    error Proxy__ImplementationIsNotContract();

    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        if (!implementation.isContract())
            revert Proxy__ImplementationIsNotContract();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.8;

interface IunCryptoManager {

    event unCryptoProxyDeployed(address deployment);

    function UNCRYPTO_DIAMOND() external view returns (address);

    function getProxy(address underlyingToken) external view returns (address proxy);

    function getProxyList() external view returns (address[] memory proxyList);

    function deployCryptoProxy(address underlyingToken, address untradingManager, uint256 managerCut, string memory name, string memory symbol, string memory baseURI) external returns (address deployment);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { IunCryptoManager } from "./IunCryptoManager.sol";
import { unCryptoProxy } from "../proxy/unCryptoProxy.sol";

import { unCryptoManagerStorage } from "./unCryptoManagerStorage.sol";

contract unCryptoManager is IunCryptoManager, OwnableInternal {
    using unCryptoManagerStorage for unCryptoManagerStorage.Layout;

    address public immutable UNCRYPTO_DIAMOND;

    constructor(address unDiamond) { //? Could put the untradingManager and managerCut in the constructor
        UNCRYPTO_DIAMOND = unDiamond;
    }

    function getProxy(address underlyingToken) external view returns (address proxy) {
        proxy = unCryptoManagerStorage.layout().getProxy(underlyingToken);
    }

    function getProxyList() external view returns (address[] memory proxyList) {
        proxyList = unCryptoManagerStorage.layout().proxyList;
    }   

    function deployCryptoProxy(
        address underlyingToken,
        address untradingManager, 
        uint256 managerCut,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) external onlyOwner returns (address deployment) {
        unCryptoManagerStorage.Layout storage m = unCryptoManagerStorage.layout();

        deployment = address(
            new unCryptoProxy(
                UNCRYPTO_DIAMOND,
                underlyingToken,
                untradingManager,
                managerCut,
                name,
                symbol,
                baseURI
            )
        );

        m.setProxy(underlyingToken, deployment);
        m.proxyList.push(deployment);

        emit unCryptoProxyDeployed(deployment);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.8;

library unCryptoManagerStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.Core.unCryptoManager.facet.storage");

    struct Layout {
        mapping(address => address) proxyAddresses; // Mapping that represents a given token's proxy/derivative contract
        address[] proxyList; // List of all created proxies
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function getProxy(Layout storage l, address underlyingToken) internal view returns (address) {
        return l.proxyAddresses[underlyingToken];
    }

    function setProxy(Layout storage l, address underlying, address proxy) internal {
        l.proxyAddresses[underlying] = proxy;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.8;

library ManagementStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unCryptoDiamond.facet.management.storage");

    struct Layout {
        address untradingManager;
        uint256 managerCut; // This is the cut of the oTokens that the untradingManager gets
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';
import { IERC165 } from "@solidstate/contracts/interfaces/IERC165.sol";
import { ERC165BaseStorage } from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseStorage.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { IERC20Metadata } from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import "@drad/eip-5173-diamond/contracts/nFR/InFR.sol";

import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

import { WrappingStorage } from "../wrapping/WrappingStorage.sol";
import { UnwrappingStorage } from "../unwrapping/UnwrappingStorage.sol";
import "../management/ManagementStorage.sol";

contract unCryptoProxy is Proxy {
    address private immutable UNCRYPTO_DIAMOND;

    using ERC165BaseStorage for ERC165BaseStorage.Layout;

    constructor(
        address unCryptoDiamond,
        address underlyingToken,
        address untradingManager,
        uint256 managerCut,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) {
        require(managerCut <= 1e18, "managerCut exceeds 100%");

        // Init Diamond Proxy
        UNCRYPTO_DIAMOND = unCryptoDiamond;

        // Init Ownable
        OwnableStorage.layout().owner = msg.sender; // If we want to incorporate ownability into each individual proxy, probably unnecessary since we have the untradingManager

        // Init the ERC721 Metadata for the unCrypto Proxy
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
        l.name = name;
        l.symbol = symbol;
        l.baseURI = baseURI;

        // Declare all interfaces supported by the Diamond
        ERC165BaseStorage.layout().supportedInterfaces[type(IERC165).interfaceId] = true;
        ERC165BaseStorage.layout().supportedInterfaces[type(IERC721).interfaceId] = true;
        ERC165BaseStorage.layout().supportedInterfaces[type(InFR).interfaceId] = true;

        // Init the WrappingStorage and set underlying token
        WrappingStorage.Layout storage w = WrappingStorage.layout();
        w.underlyingTokenAddress = underlyingToken;
        w.underlyingTokenDecimals = IERC20Metadata(underlyingToken).decimals();

        assert(w.underlyingTokenDecimals > 0 && w.underlyingTokenDecimals <= 18);

        // Init EIP-712
        UnwrappingStorage.Layout storage u = UnwrappingStorage.layout();
        u.DOMAIN_SEPARATOR = keccak256(abi.encode(UnwrappingStorage.EIP712DOMAINTYPE_HASH, keccak256(bytes(name)), UnwrappingStorage.VERSION_HASH, block.chainid, address(this), UnwrappingStorage.SALT));

        // Init the manager and managerCut used by oTokens
        ManagementStorage.Layout storage m = ManagementStorage.layout();
        m.untradingManager = untradingManager;
        m.managerCut = managerCut;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(UNCRYPTO_DIAMOND).facetAddress(msg.sig);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.8;

library UnwrappingStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unCryptoDiamond.facet.ERC20.unwrapping.storage");

    bytes32 constant EIP712DOMAINTYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    bytes32 constant VERSION_HASH = keccak256("1");

    bytes32 constant TXTYPE_HASH = keccak256("Unwrap(address to,uint256 tokenId)");

    // keccak256("untradingcrypto")
    bytes32 constant SALT = 0xc25ebea6dd97ec30f15ce845010d7e9fee0398194f29ee544b5062c074544590;

    struct Layout {
        bytes32 DOMAIN_SEPARATOR;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.8;

library WrappingStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unCryptoDiamond.facet.ERC20.wrapping.storage");

    struct Layout {
        // Every token in this contract is assumed to be wrapped, so there is no need for another underlyingAmount variable or an isWrapped bool.
        address underlyingTokenAddress;
        uint8 underlyingTokenDecimals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}