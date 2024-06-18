// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Mapping from masterContract to an array of all clones
    /// On mainnet events can be used to get this list, but events aren't always easy to retrieve and
    /// barely work on sidechains. While this adds gas, it makes enumerating all clones much easier.
    mapping(address => address[]) public clonesOf;

    /// @notice Returns the count of clones that exists for a specific masterContract
    /// @param masterContract The address of the master contract.
    /// @return cloneCount total number of clones for the masterContract.
    function clonesOfCount(address masterContract) public view returns (uint256 cloneCount) {
        cloneCount = clonesOf[masterContract].length;
    }

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;
        clonesOf[masterContract].push(cloneAddress);

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC165.sol";

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}("");
        require(success, "BoringAddress: transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "./ERC1155.sol";

// An asset is a token + a strategy
struct Asset {
    TokenType tokenType;
    address contractAddress;
    IStrategy strategy;
    uint256 tokenId;
}

contract AssetRegister is ERC1155 {
    using BoringAddress for address;

    event AssetRegistered(
        TokenType indexed tokenType,
        address indexed contractAddress,
        IStrategy strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );
    event ApprovalForAsset(address indexed sender, address indexed operator, uint256 assetId, bool approved);

    // ids start at 1 so that id 0 means it's not yet registered
    mapping(
        TokenType tokenType
            => mapping(
                address contractAddress => mapping(IStrategy strategy => mapping(uint256 tokenId => uint256 assetId))
            )
    ) public ids;
    Asset[] public assets;

    constructor() {
        assets.push(Asset(TokenType.None, address(0), NO_STRATEGY, 0));
    }

    function assetCount() public view returns (uint256) {
        return assets.length;
    }

    function _registerAsset(TokenType tokenType, address contractAddress, IStrategy strategy, uint256 tokenId)
        internal
        returns (uint256 assetId)
    {
        // Checks
        assetId = ids[tokenType][contractAddress][strategy][tokenId];

        // If assetId is 0, this is a new asset that needs to be registered
        if (assetId == 0) {
            // Only do these checks if a new asset needs to be created
            require(tokenId == 0 || tokenType != TokenType.ERC20, "YieldBox: No tokenId for ERC20");
            require(
                tokenType == TokenType.Native
                    || (
                        tokenType == strategy.tokenType() && contractAddress == strategy.contractAddress()
                            && tokenId == strategy.tokenId()
                    ),
                "YieldBox: Strategy mismatch"
            );
            // If a new token gets added, the isContract checks that this is a deployed contract. Needed for security.
            // Prevents getting shares for a future token whose address is known in advance. For instance a token that will be deployed with CREATE2 in the future or while the contract creation is
            // in the mempool
            require(
                (tokenType == TokenType.Native && contractAddress == address(0)) || contractAddress.isContract(),
                "YieldBox: Not a token"
            );

            // Effects
            assetId = assets.length;
            assets.push(Asset(tokenType, contractAddress, strategy, tokenId));
            ids[tokenType][contractAddress][strategy][tokenId] = assetId;

            // The actual URI isn't emitted here as per EIP1155, because that would make this call super expensive.
            emit URI("", assetId);
            emit AssetRegistered(tokenType, contractAddress, strategy, tokenId, assetId);
        }
    }

    function registerAsset(TokenType tokenType, address contractAddress, IStrategy strategy, uint256 tokenId)
        public
        returns (uint256 assetId)
    {
        // Native assets can only be added internally by the NativeTokenFactory
        require(
            tokenType == TokenType.ERC20 || tokenType == TokenType.ERC721 || tokenType == TokenType.ERC1155,
            "AssetManager: cannot add Native"
        );
        assetId = _registerAsset(tokenType, contractAddress, strategy, tokenId);
    }

    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external virtual {
        require(assetId < assetCount(), "AssetManager: asset not valid");
        isApprovedForAsset[msg.sender][operator][assetId] = approved;

        emit ApprovalForAsset(msg.sender, operator, assetId, approved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library BoringMath {
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function muldiv(
        uint256 value,
        uint256 mul,
        uint256 div,
        bool roundUp
    ) internal pure returns (uint256 result) {
        result = (value * mul) / div;
        if (roundUp && (result * div) / mul < value) {
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";

// Written by OreNoMochi (https://github.com/OreNoMochii), BoringCrypto

contract ERC1155 is IERC1155 {
    using BoringAddress for address;

    // mappings

    mapping(address => mapping(address => mapping(uint256 => bool)))
        public isApprovedForAsset;
    mapping(address => mapping(address => bool))
        public
        override isApprovedForAll; // map of operator approval
    mapping(address => mapping(uint256 => uint256)) public override balanceOf; // map of tokens owned by
    mapping(uint256 => uint256) public totalSupply; // totalSupply per token

    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0xd9b67a26 || // ERC-1155
            interfaceID == 0x0e89341c; // EIP-1155 Metadata
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view override returns (uint256[] memory balances) {
        uint256 len = owners.length;
        require(len == ids.length, "ERC1155: Length mismatch");

        balances = new uint256[](len);

        for (uint256 i; i < len; i++) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function _mint(address to, uint256 id, uint256 value) internal {
        require(to != address(0), "No 0 address");

        balanceOf[to][id] += value;
        totalSupply[id] += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function _burn(address from, uint256 id, uint256 value) internal {
        require(from != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        totalSupply[id] -= value;

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _transferSingle(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function _transferBatch(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal virtual {
        require(to != address(0), "No 0 address");

        uint256 len = ids.length;
        for (uint256 i; i < len; i++) {
            uint256 id = ids[i];
            _requireTransferAllowed(from, isApprovedForAsset[from][msg.sender][id]);
            
            uint256 value = values[i];
            balanceOf[from][id] -= value;
            balanceOf[to][id] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function _requireTransferAllowed(
        address _from,
        bool _approved
    ) internal view virtual {
        require(
            _from == msg.sender ||
                _approved ||
                isApprovedForAll[_from][msg.sender] == true,
            "Transfer not allowed"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _requireTransferAllowed(from, isApprovedForAsset[from][msg.sender][id]);

        _transferSingle(from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    value,
                    data
                ) ==
                    bytes4(
                        keccak256(
                            "onERC1155Received(address,address,uint256,uint256,bytes)"
                        )
                    ),
                "Wrong return value"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "ERC1155: Length mismatch");

        _transferBatch(from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    values,
                    data
                ) ==
                    bytes4(
                        keccak256(
                            "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                        )
                    ),
                "Wrong return value"
            );
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external virtual override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(
        uint256 /*assetId*/
    ) external view virtual returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";

contract ERC1155TokenReceiver is IERC1155TokenReceiver {
    // ERC1155 receivers that simple accept the transfer
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81; //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721TokenReceiver.sol";

contract ERC721TokenReceiver is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02; //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";
import "./IYieldBox.sol";

interface IStrategy {
    /// Each strategy only works with a single asset. This should help make implementations simpler and more readable.
    /// To safe gas a proxy pattern (YieldBox factory) could be used to deploy the same strategy for multiple tokens.

    /// It is recommended that strategies keep a small amount of funds uninvested (like 5%) to handle small withdrawals
    /// and deposits without triggering costly investing/divesting logic.

    /// #########################
    /// ### Basic Information ###
    /// #########################

    /// Returns the address of the yieldBox that this strategy is for
    function yieldBox() external view returns (IYieldBox yieldBox_);

    /// Returns a name for this strategy
    function name() external view returns (string memory name_);

    /// Returns a description for this strategy
    function description() external view returns (string memory description_);

    /// #######################
    /// ### Supported Token ###
    /// #######################

    /// Returns the standard that this strategy works with
    function tokenType() external view returns (TokenType tokenType_);

    /// Returns the contract address that this strategy works with
    function contractAddress() external view returns (address contractAddress_);

    /// Returns the tokenId that this strategy works with (for EIP1155)
    /// This is always 0 for EIP20 tokens
    function tokenId() external view returns (uint256 tokenId_);

    /// ###########################
    /// ### Balance Information ###
    /// ###########################

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but MUST NOT return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view returns (uint256 amount);

    /// ##########################
    /// ### YieldBox Functions ###
    /// ##########################

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// If the strategy handles native tokens (ETH) it will receive it directly (not wrapped). It will be
    /// up to the strategy to wrap it if needed.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external;

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// If the strategy handles native tokens (ETH) it should send this, not a wrapped version.
    /// With some strategies it might be hard to withdraw exactly the correct amount.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external;
}

IStrategy constant NO_STRATEGY = IStrategy(address(0));

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IWrappedNative is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import {TokenType} from "../enums/YieldBoxTokenType.sol";

interface IYieldBox {
    function registerAsset(
        TokenType tokenType,
        address contractAddress,
        address strategy,
        uint256 tokenId
    ) external returns (uint256 assetId);

    function wrappedNative() external view returns (address wrappedNative);

    function assets(
        uint256 assetId
    )
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(
        uint256 assetId
    )
        external
        view
        returns (string memory name, string memory symbol, uint8 decimals);

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(
        uint256 assetId
    ) external view returns (uint256 totalSupply);

    function setApprovalForAsset(
        address operator,
        uint256 assetId,
        bool approved
    ) external;

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AssetRegister.sol";
import "./BoringMath.sol";

struct NativeToken {
    string name;
    string symbol;
    uint8 decimals;
    string uri;
}

/// @title NativeTokenFactory
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create
/// native tokens in YieldBox. These have many benefits:
/// - low and predictable gas usage
/// - simplified approval
/// - no hidden features, all these tokens behave the same

contract NativeTokenFactory is AssetRegister {
    using BoringMath for uint256;

    mapping(uint256 => NativeToken) public nativeTokens;
    mapping(uint256 => address) public owner;

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    modifier allowed(address _from, uint256 _id) {
        _requireTransferAllowed(_from, isApprovedForAsset[_from][msg.sender][_id]);
        _;
    }

    /// @notice Only allows the `owner` to execute the function.
    /// @param tokenId The `tokenId` that the sender has to be owner of.
    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == owner[tokenId], "NTF: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// Modified slightly to change function name from `owner()` to `contractOwner()` and `onlyOwner()` to `onlyContractOwner()`
// This is to avoid conflicts with the `owner()` function and `onlyOwner()` modifier in the NativeTokenFactory contract.

pragma solidity ^0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyContractOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OZOwnable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyContractOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function contractOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(contractOwner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyContractOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyContractOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyContractOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

// The YieldBox
// The original BentoBox is owned by the Sushi team to set strategies for each token. Abracadabra wanted different strategies, which led to
// them launching their own DegenBox. The YieldBox solves this by allowing an unlimited number of strategies for each token in a fully
// permissionless manner. The YieldBox has no owner and operates fully permissionless.

// Other improvements:
// Better system to make sure the token to share ratio doesn't reset.
// Full support for rebasing tokens.

// This contract stores funds, handles their transfers, approvals and strategies.

// Copyright (c) 2021, 2022 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Since the contract is permissionless, only one deployment per chain is needed. If it's not yet deployed
// on a chain or if you want to make a derivative work, contact @BoringCrypto. The core of YieldBox is
// copyrighted. Most of the contracts that it builds on are open source though.

// BEWARE: Still under active development
// Security review not done yet

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "./interfaces/IWrappedNative.sol";
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC721TokenReceiver.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AssetRegister.sol";
import "./NativeTokenFactory.sol";
import "./YieldBoxRebase.sol";
import "./YieldBoxURIBuilder.sol";
import "./YieldBoxPermit.sol";

import {Pearlmit} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {OZOwnable} from "./OZOwnable.sol";

// solhint-disable no-empty-blocks

/// @title YieldBox
/// @author BoringCrypto, Keno
/// @notice The YieldBox is a vault for tokens. The stored tokens can assigned to strategies.
/// Yield from this will go to the token depositors.
/// Any funds transfered directly onto the YieldBox will be lost, use the deposit function instead.
contract YieldBox is
    YieldBoxPermit,
    BoringBatchable,
    NativeTokenFactory,
    ERC721TokenReceiver,
    ERC1155TokenReceiver,
    OZOwnable
{
    using BoringAddress for address;
    using BoringERC20 for IERC20;
    using BoringERC20 for IWrappedNative;
    using YieldBoxRebase for uint256;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event Deposited(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut,
        bool isNFT
    );

    event Withdraw(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut
    );

    // ******************* //
    // *** ERRORS ******** //
    // ******************* //
    error InvalidTokenType();
    error NotWrapped();
    error AmountTooLow();
    error RefundFailed();
    error ZeroAddress();
    error NotSet();
    error ForbiddenAction();
    error AssetNotValid();
    error PearlmitTransferFailed();

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    IWrappedNative public immutable wrappedNative;
    YieldBoxURIBuilder public immutable uriBuilder;
    Pearlmit public pearlmit;

    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_, Pearlmit pearlmit_, address owner_)
        YieldBoxPermit("YieldBox")
    {
        wrappedNative = wrappedNative_;
        uriBuilder = uriBuilder_;
        pearlmit = pearlmit_;
        _transferOwnership(owner_);
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /// @dev Returns the total balance of `token` the strategy contract holds,
    /// plus the total amount this contract thinks the strategy holds.
    function _tokenBalanceOf(Asset storage asset) internal view returns (uint256 amount) {
        return asset.strategy.currentBalance();
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        public
        allowed(from, assetId)
        returns (uint256 amountOut, uint256 shareOut)
    {
        // Checks
        Asset storage asset = assets[assetId];
        if (asset.tokenType == TokenType.Native) revert InvalidTokenType();
        if (asset.tokenType == TokenType.ERC721) revert InvalidTokenType();

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = amount._toShares(totalSupply[assetId], totalAmount, false);
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = share._toAmount(totalSupply[assetId], totalAmount, true);
        }

        _mint(to, assetId, share);

        // Interactions
        if (asset.tokenType == TokenType.ERC20) {
            (uint256 allowedAmount,) = pearlmit.allowance(from, address(this), 20, asset.contractAddress, 0);

            // Check whether the tokens are Pearlmit approved
            if (allowedAmount >= amount) {
                // If approved, use the Pearlmit transfer function
                bool isErr = pearlmit.transferFromERC20(from, address(asset.strategy), asset.contractAddress, amount);
                if (isErr) revert PearlmitTransferFailed();
            } else {
                // If not approved through Pearlmit, use the token transfer function
                // For ERC20 tokens, use the safe helper function to deal with broken ERC20 implementations. This actually calls transferFrom on the ERC20 contract.
                IERC20(asset.contractAddress).safeTransferFrom(from, address(asset.strategy), amount);
            }
        } else {
            // ERC1155
            // When depositing yieldBox tokens into the yieldBox, things can be simplified
            if (asset.contractAddress == address(this)) {
                _transferSingle(from, address(asset.strategy), asset.tokenId, amount);
            } else {
                (uint256 allowedAmount,) =
                    pearlmit.allowance(from, address(this), 1155, asset.contractAddress, asset.tokenId);

                // Check whether the tokens are Pearlmit approved
                if (allowedAmount >= amount) {
                    // If approved, use the Pearlmit transfer function
                    bool isErr = pearlmit.transferFromERC1155(
                        from, address(asset.strategy), asset.contractAddress, asset.tokenId, amount
                    );
                    if (isErr) revert PearlmitTransferFailed();
                } else {
                    // If not approved through Pearlmit, use the token transfer function
                    IERC1155(asset.contractAddress).safeTransferFrom(
                        from, address(asset.strategy), asset.tokenId, amount, ""
                    );
                }
            }
        }

        asset.strategy.deposited(amount);

        emit Deposited(msg.sender, from, to, assetId, amount, share, amountOut, shareOut, false);

        return (amount, share);
    }

    /// @notice Deposit an NFT asset
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositNFTAsset(uint256 assetId, address from, address to)
        public
        allowed(from, assetId)
        returns (uint256 amountOut, uint256 shareOut)
    {
        // Checks
        Asset storage asset = assets[assetId];
        if (asset.tokenType != TokenType.ERC721) revert InvalidTokenType();

        // Effects
        _mint(to, assetId, 1);

        // Interactions
        (uint256 allowedAmount,) = pearlmit.allowance(from, address(this), 721, asset.contractAddress, asset.tokenId);

        // Check whether the tokens are Pearlmit approved
        if (allowedAmount > 0) {
            // If approved, use the Pearlmit transfer function
            bool isErr =
                pearlmit.transferFromERC721(from, address(asset.strategy), asset.contractAddress, asset.tokenId);
            if (isErr) revert PearlmitTransferFailed();
        } else {
            // If not approved through Pearlmit, use the token transfer function
            IERC721(asset.contractAddress).safeTransferFrom(from, address(asset.strategy), asset.tokenId);
        }

        asset.strategy.deposited(1);

        emit Deposited(msg.sender, from, to, assetId, 1, 1, 1, 1, true);

        return (1, 1);
    }

    /// @notice Deposit ETH asset
    /// @param assetId The id of the asset.
    /// @param to which account to push the tokens.
    /// @param amount ETH amount to deposit.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositETHAsset(uint256 assetId, address to, uint256 amount)
        public
        payable
        returns (uint256 amountOut, uint256 shareOut)
    {
        // Checks
        Asset storage asset = assets[assetId];
        if (asset.tokenType != TokenType.ERC20) revert InvalidTokenType();
        if (asset.contractAddress != address(wrappedNative)) {
            revert NotWrapped();
        }
        if (msg.value < amount) revert AmountTooLow();

        // Effects
        uint256 share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(asset), false);

        _mint(to, assetId, share);

        // Interactions
        wrappedNative.deposit{value: amount}();
        // Strategies always receive wrappedNative (supporting both wrapped and raw native tokens adds too much complexity)
        wrappedNative.safeTransfer(address(asset.strategy), amount);
        asset.strategy.deposited(amount);

        emit Deposited(msg.sender, msg.sender, to, assetId, amount, share, amountOut, shareOut, false);

        if (msg.value > amount) {
            (bool success,) = msg.sender.call{value: msg.value - amount}(new bytes(0));
            if (!success) revert RefundFailed();
        }

        return (amount, share);
    }

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        public
        allowed(from, assetId)
        returns (uint256 amountOut, uint256 shareOut)
    {
        // Checks
        Asset storage asset = assets[assetId];
        if (asset.tokenType == TokenType.Native) revert InvalidTokenType();

        // Handle ERC721 separately
        if (asset.tokenType == TokenType.ERC721) {
            return _withdrawNFT(asset, assetId, from, to);
        }

        return _withdrawFungible(asset, assetId, from, to, amount, share);
    }

    /// @notice Handles burning and withdrawal of ERC20 and 1155 tokens.
    /// @param asset The asset to withdraw.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    function _withdrawNFT(Asset storage asset, uint256 assetId, address from, address to)
        internal
        returns (uint256 amountOut, uint256 shareOut)
    {
        _burn(from, assetId, 1);

        // Interactions
        asset.strategy.withdraw(to, 1);

        emit Withdraw(msg.sender, from, to, assetId, 1, 1, 1, 1);

        return (1, 1);
    }

    /// @notice Handles burning and withdrawal of ERC20 and 1155 tokens.
    /// @param asset The asset to withdraw.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function _withdrawFungible(
        Asset storage asset,
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = amount._toShares(totalSupply[assetId], totalAmount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = share._toAmount(totalSupply[assetId], totalAmount, false);
        }

        _burn(from, assetId, share);

        // Interactions
        asset.strategy.withdraw(to, amount);

        emit Withdraw(msg.sender, from, to, assetId, amount, share, amountOut, shareOut);

        return (amount, share);
    }

    /// @notice Transfer shares from a user account to another one.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param assetId The id of the asset.
    /// @param share The amount of `token` in shares.
    function transfer(address from, address to, uint256 assetId, uint256 share) public allowed(from, assetId) {
        _transferSingle(from, to, assetId, share);
    }

    function batchTransfer(address from, address to, uint256[] calldata assetIds_, uint256[] calldata shares_) public {
        uint256 len = assetIds_.length;

        unchecked {
            for (uint256 i; i < len; i++) {
                _requireTransferAllowed(from, isApprovedForAsset[from][msg.sender][assetIds_[i]]);
            }
        }

        _transferBatch(from, to, assetIds_, shares_);
    }

    function _transferBatch(address from, address to, uint256[] calldata ids, uint256[] calldata values)
        internal
        override
    {
        if (to == address(0)) revert ZeroAddress();

        uint256 len = ids.length;
        unchecked {
            for (uint256 i; i < len; i++) {
                balanceOf[from][ids[i]] -= values[i];
                balanceOf[to][ids[i]] += values[i];
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    /// @notice Transfer shares from a user account to multiple other ones.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param tos The receivers of the tokens.
    /// @param shares The amount of `token` in shares for each receiver in `tos`.
    function transferMultiple(address from, address[] calldata tos, uint256 assetId, uint256[] calldata shares)
        public
        allowed(from, assetId)
    {
        uint256 len = tos.length;
        uint256 _totalShares;
        unchecked {
            for (uint256 i; i < len; i++) {
                if (tos[i] == address(0)) revert ZeroAddress();
                balanceOf[tos[i]][assetId] += shares[i];
                _totalShares += shares[i];
                emit TransferSingle(msg.sender, from, tos[i], assetId, shares[i]);
            }
        }
        balanceOf[from][assetId] -= _totalShares;
    }

    /// @notice Update approval status for an operator
    /// @param operator The address approved to perform actions on your behalf
    /// @param approved True/False
    function setApprovalForAll(address operator, bool approved) external override {
        // Checks
        if (operator == address(0)) revert NotSet();
        if (operator == address(this)) revert ForbiddenAction();

        // Effects
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Update approval status for an operator
    /// @param _owner The YieldBox account owner
    /// @param operator The address approved to perform actions on your behalf
    /// @param approved True/False
    function _setApprovalForAll(address _owner, address operator, bool approved) internal override {
        isApprovedForAll[_owner][operator] = approved;
        emit ApprovalForAll(_owner, operator, approved);
    }

    /// @notice Update approval status for an operator and for a specific asset
    /// @param operator The address approved to perform actions on your behalf
    /// @param assetId The asset id  to update approval status for
    /// @param approved True/False
    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external override {
        // Checks
        if (operator == address(0)) revert NotSet();
        if (operator == address(this)) revert ForbiddenAction();

        // Effects
        _setApprovalForAsset(msg.sender, operator, assetId, approved);
    }

    /// @notice Update approval status for an operator and for a specific asset
    /// @param _owner The owner of the asset
    /// @param operator The address approved to perform actions on your behalf
    /// @param assetId The asset id  to update approval status for
    /// @param approved True/False
    function _setApprovalForAsset(address _owner, address operator, uint256 assetId, bool approved) internal override {
        if (assetId >= assetCount()) revert AssetNotValid();
        isApprovedForAsset[_owner][operator][assetId] = approved;
        emit ApprovalForAsset(_owner, operator, assetId, approved);
    }

    // This functionality has been split off into a separate contract. This is only a view function, so gas usage isn't a huge issue.
    // This keeps the YieldBox contract smaller, so it can be optimized more.
    function uri(uint256 assetId) external view override returns (string memory) {
        return uriBuilder.uri(assets[assetId], nativeTokens[assetId], totalSupply[assetId], owner[assetId]);
    }

    function name(uint256 assetId) external view returns (string memory) {
        return uriBuilder.name(assets[assetId], nativeTokens[assetId].name);
    }

    function symbol(uint256 assetId) external view returns (string memory) {
        return uriBuilder.symbol(assets[assetId], nativeTokens[assetId].symbol);
    }

    function decimals(uint256 assetId) external view returns (uint8) {
        return uriBuilder.decimals(assets[assetId], nativeTokens[assetId].decimals);
    }

    // Helper functions

    /// @notice Helper function to return totals for an asset
    /// @param assetId The regierestered asset id
    /// @return totalShare The total amount for asset represented in shares
    /// @return totalAmount The total amount for asset
    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount) {
        totalShare = totalSupply[assetId];
        totalAmount = _tokenBalanceOf(assets[assetId]);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param assetId The id of the asset.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            share = amount;
        } else {
            share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent shares back into the `token` amount.
    /// @param assetId The id of the asset.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = share;
        } else {
            amount = share._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent the balance in `token` amount for a `user` for an `asset`.
    /// @param user The `user` to get the amount for.
    /// @param assetId The id of the asset.
    function amountOf(address user, uint256 assetId) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = balanceOf[user][assetId];
        } else {
            amount = balanceOf[user][assetId]._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), false);
        }
    }

    /// @notice Helper function to register & deposit an asset
    /// @param tokenType Registration token type.
    /// @param contractAddress Token address.
    /// @param strategy Asset's strategy address.
    /// @param tokenId Registration token id.
    /// @param from which user to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount amount to deposit.
    /// @param share amount to deposit represented in shares.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public returns (uint256 amountOut, uint256 shareOut) {
        if (tokenType == TokenType.Native) {
            // If native token, register it as an ERC1155 asset (as that's what it is)
            return depositAsset(
                registerAsset(TokenType.ERC1155, address(this), strategy, tokenId), from, to, amount, share
            );
        } else {
            return depositAsset(registerAsset(tokenType, contractAddress, strategy, tokenId), from, to, amount, share);
        }
    }

    /// @notice Helper function to register & deposit ETH
    /// @param strategy Asset's strategy address.
    /// @param amount amount to deposit.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositETH(IStrategy strategy, address to, uint256 amount)
        public
        payable
        returns (uint256 amountOut, uint256 shareOut)
    {
        return depositETHAsset(registerAsset(TokenType.ERC20, address(wrappedNative), strategy, 0), to, amount);
    }

    // ******************* //
    //    *** OWNER ***    //
    // ******************* //

    /// @notice Set the Pearlmit contract
    /// @param pearlmit_ The new Pearlmit contract address
    function setPearlmit(Pearlmit pearlmit_) external onlyContractOwner {
        pearlmit = pearlmit_;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IYieldBox.sol";

/**
 * Modification of the OpenZeppelin ERC20Permit contract to support ERC721 tokens.
 * OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol).
 *
 * @dev Implementation of the ERC-4494 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-4494[EIP-4494].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract YieldBoxPermit is EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 assetId,uint256 nonce,uint256 deadline)"
        );
    bytes32 private constant _REVOKE_TYPEHASH =
        keccak256(
            "Revoke(address owner,address spender,uint256 assetId,uint256 nonce,uint256 deadline)"
        );

    bytes32 private constant _PERMIT_ALL_TYPEHASH =
        keccak256(
            "PermitAll(address owner,address spender,uint256 nonce,uint256 deadline)"
        );
    bytes32 private constant _REVOKE_ALL_TYPEHASH =
        keccak256(
            "RevokeAll(address owner,address spender,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC721 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    function permit(
        address owner,
        address spender,
        uint256 assetId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permit(owner, spender, assetId, deadline, v, r, s, true);
    }

    function revoke(
        address owner,
        address spender,
        uint256 assetId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permit(owner, spender, assetId, deadline, v, r, s, false);
    }

    function _permit(
        address owner,
        address spender,
        uint256 assetId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool state
    ) private {
        require(
            block.timestamp <= deadline,
            "YieldBoxPermit: expired deadline"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                state ? _PERMIT_TYPEHASH : _REVOKE_TYPEHASH,
                owner,
                spender,
                assetId,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "YieldBoxPermit: invalid signature");

        _setApprovalForAsset(owner, spender, assetId, state);
    }

    function _setApprovalForAsset(
        address owner,
        address spender,
        uint256 assetId,
        bool approved
    ) internal virtual;

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permitAll(owner, spender, deadline, v, r, s, true);
    }

    function revokeAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permitAll(owner, spender, deadline, v, r, s, false);
    }

    function _permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool state
    ) private {
        require(
            block.timestamp <= deadline,
            "YieldBoxPermit: expired deadline"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                state ? _PERMIT_ALL_TYPEHASH : _REVOKE_ALL_TYPEHASH,
                owner,
                spender,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "YieldBoxPermit: invalid signature");

        _setApprovalForAll(owner, spender, state);
    }

    function _setApprovalForAll(
        address _owner,
        address operator,
        bool approved
    ) internal virtual;

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     */
    function _useNonce(
        address owner
    ) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

library YieldBoxRebase {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function _toShares(
        uint256 amount,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the shares using te current amount to share ratio
        share = (amount * totalShares_) / totalAmount;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (share * totalAmount) / totalShares_ < amount) {
            share++;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function _toAmount(
        uint256 share,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the amount using te current amount to share ratio
        amount = (share * totalAmount) / totalShares_;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (amount * totalShares_) / totalAmount < share) {
            amount++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "./interfaces/IYieldBox.sol";
import "./NativeTokenFactory.sol";

// solhint-disable quotes

contract YieldBoxURIBuilder {
    using BoringERC20 for IERC20;
    using Strings for uint256;
    using Base64 for bytes;

    struct AssetDetails {
        string tokenType;
        string name;
        string symbol;
        uint256 decimals;
    }

    function name(
        Asset calldata asset,
        string calldata nativeName
    ) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            return nativeName;
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return
                    string(
                        abi.encodePacked(
                            token.safeName(),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(
                        abi.encodePacked(
                            string(
                                abi.encodePacked(
                                    "ERC1155:",
                                    uint256(uint160(asset.contractAddress))
                                        .toHexString(20),
                                    "/",
                                    asset.tokenId.toString()
                                )
                            ),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else {
                return
                    string(
                        abi.encodePacked(
                            nativeName,
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            }
        }
    }

    function symbol(
        Asset calldata asset,
        string calldata nativeSymbol
    ) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            return nativeSymbol;
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return
                    string(
                        abi.encodePacked(
                            token.safeSymbol(),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(
                        abi.encodePacked(
                            "ERC1155",
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else {
                return
                    string(
                        abi.encodePacked(
                            nativeSymbol,
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            }
        }
    }

    function decimals(
        Asset calldata asset,
        uint8 nativeDecimals
    ) external view returns (uint8) {
        if (asset.tokenType == TokenType.ERC1155) {
            return 0;
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            return token.safeDecimals();
        } else {
            return nativeDecimals;
        }
    }

    function uri(
        Asset calldata asset,
        NativeToken calldata nativeToken,
        uint256 totalSupply,
        address owner
    ) external view returns (string memory) {
        AssetDetails memory details;
        if (asset.tokenType == TokenType.ERC1155) {
            // Contracts can't retrieve URIs, so the details are out of reach
            details.tokenType = "ERC1155";
            details.name = string(
                abi.encodePacked(
                    "ERC1155:",
                    uint256(uint160(asset.contractAddress)).toHexString(20),
                    "/",
                    asset.tokenId.toString()
                )
            );
            details.symbol = "ERC1155";
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            details = AssetDetails(
                "ERC20",
                token.safeName(),
                token.safeSymbol(),
                token.safeDecimals()
            );
        } else {
            // Native
            details.tokenType = "Native";
            details.name = nativeToken.name;
            details.symbol = nativeToken.symbol;
            details.decimals = nativeToken.decimals;
        }

        string memory properties = string(
            asset.tokenType != TokenType.Native
                ? abi.encodePacked(
                    ',"tokenAddress":"',
                    uint256(uint160(asset.contractAddress)).toHexString(20),
                    '"'
                )
                : abi.encodePacked(
                    ',"totalSupply":',
                    totalSupply.toString(),
                    ',"fixedSupply":',
                    owner == address(0) ? "true" : "false"
                )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    abi
                        .encodePacked(
                            '{"name":"',
                            details.name,
                            '","symbol":"',
                            details.symbol,
                            '"',
                            asset.tokenType == TokenType.ERC1155
                                ? ""
                                : ',"decimals":',
                            asset.tokenType == TokenType.ERC1155
                                ? ""
                                : details.decimals.toString(),
                            ',"properties":{"strategy":"',
                            uint256(uint160(address(asset.strategy)))
                                .toHexString(20),
                            '","tokenType":"',
                            details.tokenType,
                            '"',
                            properties,
                            asset.tokenType == TokenType.ERC1155
                                ? string(
                                    abi.encodePacked(
                                        ',"tokenId":',
                                        asset.tokenId.toString()
                                    )
                                )
                                : "",
                            "}}"
                        )
                        .encode()
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
                                                     @@@@@@@@@@@@@@             
                                                    @@@@@@@@@@@@@@@@@@(         
                                                   @@@@@@@@@@@@@@@@@@@@@        
                                                  @@@@@@@@@@@@@@@@@@@@@@@@      
                                                           #@@@@@@@@@@@@@@      
                                                               @@@@@@@@@@@@     
                            @@@@@@@@@@@@@@*                    @@@@@@@@@@@@     
                           @@@@@@@@@@@@@@@     @               @@@@@@@@@@@@     
                          @@@@@@@@@@@@@@@     @                @@@@@@@@@@@      
                         @@@@@@@@@@@@@@@     @@               @@@@@@@@@@@@      
                        @@@@@@@@@@@@@@@     #@@             @@@@@@@@@@@@/       
                        @@@@@@@@@@@@@@.     @@@@@@@@@@@@@@@@@@@@@@@@@@@         
                       @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@            
                      @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@             
                     @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@           
                    @@@@@@@@@@@@@@@     @@@@@&%%%%%%%%&&@@@@@@@@@@@@@@          
                    @@@@@@@@@@@@@@      @@@@@               @@@@@@@@@@@         
                   @@@@@@@@@@@@@@@     @@@@@                 @@@@@@@@@@@        
                  @@@@@@@@@@@@@@@     @@@@@@                 @@@@@@@@@@@        
                 @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@        
                @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@&        
                @@@@@@@@@@@@@@     *@@@@@@@               (@@@@@@@@@@@@         
               @@@@@@@@@@@@@@@     @@@@@@@@             @@@@@@@@@@@@@@          
              @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           
             @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            
            @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              
           .@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
           @@@@@@@@@@@@@@%     @@@@@@@@@@@@@@@@@@@@@@@@(                        
          @@@@@@@@@@@@@@@                                                       
         @@@@@@@@@@@@@@@                                                        
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                                          
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                           
 
* @title CollateralizedPausableFlags
* @custom:version 1.0.0
* @author Limit Break, Inc.
* @description Collateralized Pausable Flags is an extension for contracts
*              that require features to be pausable in the event of potential
*              or actual threats without incurring a storage read overhead cost
*              during normal operations by using contract starting balance as
*              a signal for checking the paused state.
*
*              Using contract balance to enable checking paused state creates an
*              economic penalty for developers that deploy code that can be 
*              exploited as well as an economic incentive (recovery of collateral)
*              for them to mitigate the threat.
*
*              Developers implementing Collateralized Pausable Flags should consider
*              their risk mitigation strategy and ensure funds are readily available
*              for pausing if ever necessary by setting an appropriate threshold 
*              value and considering use of an escrow contract that can initiate the
*              pause with funds.
*
*              There is no restriction on the depositor as this can be easily 
*              circumvented through a `SELFDESTRUCT` opcode.
*
*              Developers must be aware of potential outflows from the contract that
*              could reduce collateral below the pausable check threshold and protect
*              against those methods when pausing is required.
*/
abstract contract CollateralizedPausableFlags {
    /// @dev Emitted when the pausable flags are updated
    event PausableFlagsUpdated(uint256 previousFlags, uint256 newFlags);

    /// @dev Thrown when an execution path requires a flag to not be paused but it is paused
    error CollateralizedPausableFlags__Paused();
    /// @dev Thrown when an executin path requires a flag to be paused but it is not paused
    error CollateralizedPausableFlags__NotPaused();
    /// @dev Thrown when a call to withdraw funds fails
    error CollateralizedPausableFlags__WithdrawFailed();

    /// @dev Immutable variable that defines the native funds threshold before flags are checked
    uint256 private immutable nativeValueToCheckPauseState;
    /// @dev Flags for current pausable state, each bit is considered a separate flag
    uint256 private pausableFlags;

    /// @dev Immutable pointer for the _requireNotPaused function to use based on value threshold
    function(uint256) internal view immutable _requireNotPaused;
    /// @dev Immutable pointer for the _requirePaused function to use based on value threshold
    function(uint256) internal view immutable _requirePaused;
    /// @dev Immutable pointer for the _getPausableFlags function to use based on value threshold
    function() internal view returns (uint256) immutable _getPausableFlags;

    constructor(uint256 _nativeValueToCheckPauseState) {
        // Optimizes value check at runtime by reducing the stored immutable
        // value by 1 so that greater than can be used instead of greater
        // than or equal while allowing the deployment parameter to reflect
        // the value at which the deployer wants to trigger pause checking.
        // Example:
        //     Constructed with a value of 1000
        //     Immutable value stored is 999
        //     State checking enabled at 1000 units deposited because
        //     1000 > 999 evaluates true
        if (_nativeValueToCheckPauseState > 0) {
            unchecked {
                _nativeValueToCheckPauseState -= 1;
            }
            _requireNotPaused = _requireNotPausedWithCollateralCheck;
            _requirePaused = _requirePausedWithCollateralCheck;
            _getPausableFlags = _getPausableFlagsWithCollateralCheck;
        } else {
            _requireNotPaused = _requireNotPausedWithoutCollateralCheck;
            _requirePaused = _requirePausedWithoutCollateralCheck;
            _getPausableFlags = _getPausableFlagsWithoutCollateralCheck;
        }

        nativeValueToCheckPauseState = _nativeValueToCheckPauseState;
    }

    /**
     * @dev  Modifier to make a function callable only when the specified flags are not paused
     * @dev  Throws when any of the flags specified are paused
     *
     * @param _flags  The flags to check for pause state
     */
    modifier whenNotPaused(uint256 _flags) {
        _requireNotPaused(_flags);
        _;
    }

    /**
     * @dev  Modifier to make a function callable only when the specified flags are paused
     * @dev  Throws when any of the flags specified are not paused
     *
     * @param _flags  The flags to check for pause state
     */
    modifier whenPaused(uint256 _flags) {
        _requirePaused(_flags);
        _;
    }

    /**
     * @dev  Modifier to make a function callable only by a permissioned account
     * @dev  Throws when the caller does not have permission
     */
    modifier onlyPausePermissionedCaller() {
        _requireCallerHasPausePermissions();
        _;
    }

    /**
     * @notice  Updates the pausable flags settings
     *
     * @dev     Throws when the caller does not have permission
     * @dev     **NOTE:** Pausable flag settings will only take effect if contract balance exceeds
     * @dev     `nativeValueToPause`
     *
     * @dev     <h4>Postconditions:</h4>
     * @dev     1. address(this).balance increases by msg.value
     * @dev     2. `pausableFlags` is set to the new value
     * @dev     3. Emits a PausableFlagsUpdated event
     *
     * @param _pausableFlags  The new pausable flags to set
     */
    function pause(uint256 _pausableFlags) external payable onlyPausePermissionedCaller {
        _setPausableFlags(_pausableFlags);
    }

    /**
     * @notice  Allows any account to supply funds for enabling the pausable checks
     *
     * @dev     **NOTE:** The threshold check for pausable collateral does not pause
     * @dev     any functions unless the associated pausable flag is set.
     */
    function pausableDepositCollateral() external payable {
        // thank you for your contribution to safety
    }

    /**
     * @notice  Resets all pausable flags to unpaused and withdraws funds
     *
     * @dev     Throws when the caller does not have permission
     *
     * @dev     <h4>Postconditions:</h4>
     * @dev     1. `pausableFlags` is set to zero
     * @dev     2. Emits a PausableFlagsUpdated event
     * @dev     3. Transfers `withdrawAmount` of native funds to `withdrawTo` if non-zero
     *
     * @param withdrawTo      The address to withdraw the collateral to
     * @param withdrawAmount  The amount of collateral to withdraw
     */
    function unpause(address withdrawTo, uint256 withdrawAmount) external onlyPausePermissionedCaller {
        _setPausableFlags(0);

        if (withdrawAmount > 0) {
            (bool success,) = withdrawTo.call{value: withdrawAmount}("");
            if (!success) revert CollateralizedPausableFlags__WithdrawFailed();
        }
    }

    /**
     * @notice  Returns collateralized pausable configuration information
     *
     * @return _nativeValueToCheckPauseState  The collateral required to enable pause state checking
     * @return _pausableFlags                 The current pausable flags set, only checked when collateral met
     */
    function pausableConfigurationSettings()
        external
        view
        returns (uint256 _nativeValueToCheckPauseState, uint256 _pausableFlags)
    {
        unchecked {
            _nativeValueToCheckPauseState = nativeValueToCheckPauseState + 1;
            _pausableFlags = pausableFlags;
        }
    }

    /**
     * @notice  Updates the `pausableFlags` variable and emits a PausableFlagsUpdated event
     *
     * @param _pausableFlags  The new pausable flags to set
     */
    function _setPausableFlags(uint256 _pausableFlags) internal {
        uint256 previousFlags = pausableFlags;

        pausableFlags = _pausableFlags;

        emit PausableFlagsUpdated(previousFlags, _pausableFlags);
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if any are paused
     *
     * @dev     *Should* be called prior to any transfers of native funds out of the contract for efficiency
     * @dev     Throws when the native funds balance is greater than the value to enable pausing AND
     * @dev     one or more of the supplied `_flags` is paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requireNotPausedWithCollateralCheck(uint256 _flags) private view {
        if (_nativeBalanceSubMsgValue() > nativeValueToCheckPauseState) {
            if (pausableFlags & _flags > 0) {
                revert CollateralizedPausableFlags__Paused();
            }
        }
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if any are paused
     *
     * @dev     Throws when one or more of the supplied `_flags` is paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requireNotPausedWithoutCollateralCheck(uint256 _flags) private view {
        if (pausableFlags & _flags > 0) {
            revert CollateralizedPausableFlags__Paused();
        }
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if none are paused
     *
     * @dev     *Should* be called prior to any transfers of native funds out of the contract for efficiency
     * @dev     Throws when the native funds balance is not greater than the value to enable pausing OR
     * @dev     none of the supplied `_flags` are paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requirePausedWithCollateralCheck(uint256 _flags) private view {
        if (_nativeBalanceSubMsgValue() <= nativeValueToCheckPauseState) {
            revert CollateralizedPausableFlags__NotPaused();
        } else if (pausableFlags & _flags == 0) {
            revert CollateralizedPausableFlags__NotPaused();
        }
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if none are paused
     *
     * @dev     Throws when none of the supplied `_flags` are paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requirePausedWithoutCollateralCheck(uint256 _flags) private view {
        if (pausableFlags & _flags == 0) {
            revert CollateralizedPausableFlags__NotPaused();
        }
    }

    /**
     * @notice  Returns the current state of the pausable flags
     *
     * @dev     Will return zero if the native funds balance is not greater than the value to enable pausing
     *
     * @return _pausableFlags  The current state of the pausable flags
     */
    function _getPausableFlagsWithCollateralCheck() private view returns (uint256 _pausableFlags) {
        if (_nativeBalanceSubMsgValue() > nativeValueToCheckPauseState) {
            _pausableFlags = pausableFlags;
        }
    }

    /**
     * @notice  Returns the current state of the pausable flags
     *
     * @return _pausableFlags  The current state of the pausable flags
     */
    function _getPausableFlagsWithoutCollateralCheck() private view returns (uint256 _pausableFlags) {
        _pausableFlags = pausableFlags;
    }

    /**
     * @notice  Returns the current contract balance minus the value sent with the call
     *
     * @dev     This is expected to be the contract balance at the beginning of a function call
     * @dev     to efficiently determine whether a contract has the necessary collateral to enable
     * @dev     the pausable flags checking for contracts that hold native token funds.
     * @dev     This should **NOT** be used in any way to determine current balance for contract logic
     * @dev     other than its intended purpose for pause state checking activation.
     */
    function _nativeBalanceSubMsgValue() private view returns (uint256 _value) {
        unchecked {
            _value = address(this).balance - msg.value;
        }
    }

    /**
     * @dev  To be implemented by an inheriting contract for authorization to `pause` and `unpause`
     * @dev  functions as well as any functions in the inheriting contract that utilize the
     * @dev  `onlyPausePermissionedCaller` modifier.
     *
     * @dev  Implementing contract function **MUST** throw when the caller is not permissioned
     */
    function _requireCallerHasPausePermissions() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Constant bytes32 value of 0x000...000
bytes32 constant ZERO_BYTES32 = bytes32(0);

/// @dev Constant value of 0
uint256 constant ZERO = 0;
/// @dev Constant value of 1
uint256 constant ONE = 1;

/// @dev Constant value representing an open order in storage
uint8 constant ORDER_STATE_OPEN = 0;
/// @dev Constant value representing a filled order in storage
uint8 constant ORDER_STATE_FILLED = 1;
/// @dev Constant value representing a cancelled order in storage
uint8 constant ORDER_STATE_CANCELLED = 2;

/// @dev Constant value representing the ERC721 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC721 = 721;
/// @dev Constant value representing the ERC1155 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC1155 = 1155;
/// @dev Constant value representing the ERC20 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC20 = 20;

/// @dev Constant value to mask the upper bits of a signature that uses a packed `vs` value to extract `s`
bytes32 constant UPPER_BIT_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

/// @dev EIP-712 typehash used for validating signature based stored approvals
bytes32 constant UPDATE_APPROVAL_TYPEHASH =
    keccak256("UpdateApprovalBySignature(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 approvalExpiration,uint256 sigDeadline,uint256 masterNonce)");

/// @dev EIP-712 typehash used for validating a single use permit without additional data
bytes32 constant SINGLE_USE_PERMIT_TYPEHASH =
    keccak256("PermitTransferFrom(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 expiration,uint256 masterNonce)");

/// @dev EIP-712 typehash used for validating a single use permit with additional data
string constant SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB =
    "PermitTransferFromWithAdditionalData(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 expiration,uint256 masterNonce,";

/// @dev EIP-712 typehash used for validating an order permit that updates storage as it fills
string constant PERMIT_ORDER_ADVANCED_TYPEHASH_STUB =
    "PermitOrderWithAdditionalData(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 salt,address operator,uint256 expiration,uint256 masterNonce,";

/// @dev Pausable flag for stored approval transfers of ERC721 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721 = 1 << 0;
/// @dev Pausable flag for stored approval transfers of ERC1155 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155 = 1 << 1;
/// @dev Pausable flag for stored approval transfers of ERC20 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20 = 1 << 2;

/// @dev Pausable flag for single use permit transfers of ERC721 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721 = 1 << 3;
/// @dev Pausable flag for single use permit transfers of ERC1155 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155 = 1 << 4;
/// @dev Pausable flag for single use permit transfers of ERC20 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20 = 1 << 5;

/// @dev Pausable flag for order fill transfers of ERC1155 assets
uint256 constant PAUSABLE_ORDER_TRANSFER_FROM_ERC1155 = 1 << 6;
/// @dev Pausable flag for order fill transfers of ERC20 assets
uint256 constant PAUSABLE_ORDER_TRANSFER_FROM_ERC20 = 1 << 7;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Storage data struct for stored approvals and order approvals
struct PackedApproval {
    // Only used for partial fill position 1155 transfers
    uint8 state;
    // Amount allowed
    uint200 amount;
    // Permission expiry
    uint48 expiration;
}

/// @dev Calldata data struct for order fill amounts
struct OrderFillAmounts {
    uint256 orderStartAmount;
    uint256 requestedFillAmount;
    uint256 minimumFillAmount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Thrown when a stored approval exceeds type(uint200).max
error PermitC__AmountExceedsStorageMaximum();

/// @dev Thrown when a transfer amount requested exceeds the permitted amount
error PermitC__ApprovalTransferExceededPermittedAmount();

/// @dev Thrown when a transfer is requested after the permit has expired
error PermitC__ApprovalTransferPermitExpiredOrUnset();

/// @dev Thrown when attempting to close an order by an account that is not the owner or operator
error PermitC__CallerMustBeOwnerOrOperator();

/// @dev Thrown when attempting to approve a token type that is not valid for PermitC
error PermitC__InvalidTokenType();

/// @dev Thrown when attempting to invalidate a nonce that has already been used
error PermitC__NonceAlreadyUsedOrRevoked();

/// @dev Thrown when attempting to restore a nonce that has not been used
error PermitC__NonceNotUsedOrRevoked();

/// @dev Thrown when attempting to fill an order that has already been filled or cancelled
error PermitC__OrderIsEitherCancelledOrFilled();

/// @dev Thrown when a transfer amount requested exceeds the permitted amount
error PermitC__SignatureTransferExceededPermittedAmount();

/// @dev Thrown when a transfer is requested after the permit has expired
error PermitC__SignatureTransferExceededPermitExpired();

/// @dev Thrown when attempting to use an advanced permit typehash that is not registered
error PermitC__SignatureTransferPermitHashNotRegistered();

/// @dev Thrown when a permit signature is invalid
error PermitC__SignatureTransferInvalidSignature();

/// @dev Thrown when the remaining fill amount is less than the requested minimum fill
error PermitC__UnableToFillMinimumRequestedQuantity();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {OrderFillAmounts} from "../DataTypes.sol";

interface IPermitC {

    /**
     * =================================================
     * ==================== Events =====================
     * =================================================
     */

    /// @dev Emitted when an approval is stored
    event Approval(
        address indexed owner,
        address indexed token,
        address indexed operator,
        uint256 id,
        uint200 amount,
        uint48 expiration
    );

    /// @dev Emitted when a user increases their master nonce
    event Lockdown(address indexed owner);

    /// @dev Emitted when an order is opened
    event OrderOpened(
        bytes32 indexed orderId,
        address indexed owner,
        address indexed operator,
        uint256 fillableQuantity
    );

    /// @dev Emitted when an order has a fill
    event OrderFilled(
        bytes32 indexed orderId,
        address indexed owner,
        address indexed operator,
        uint256 amount
    );

    /// @dev Emitted when an order has been fully filled or cancelled
    event OrderClosed(
        bytes32 indexed orderId, 
        address indexed owner, 
        address indexed operator, 
        bool wasCancellation);

    /// @dev Emitted when an order has an amount restored due to a failed transfer
    event OrderRestored(
        bytes32 indexed orderId,
        address indexed owner,
        uint256 amountRestoredToOrder
    );

    /**
     * =================================================
     * ============== Approval Transfers ===============
     * =================================================
     */
    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration) external;

    function updateApprovalBySignature(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 nonce,
        uint200 amount,
        address operator,
        uint48 approvalExpiration,
        uint48 sigDeadline,
        address owner,
        bytes calldata signedPermit
    ) external;

    function allowance(
        address owner, 
        address operator, 
        uint256 tokenType,
        address token, 
        uint256 id
    ) external view returns (uint256 amount, uint256 expiration);

    /**
     * =================================================
     * ================ Signed Transfers ===============
     * =================================================
     */
    function registerAdditionalDataHash(string memory additionalDataTypeString) external;

    function permitTransferFromERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromWithAdditionalDataERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromWithAdditionalDataERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromWithAdditionalDataERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function isRegisteredTransferAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered);

    function isRegisteredOrderAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered);

    /**
     * =================================================
     * =============== Order Transfers =================
     * =================================================
     */
    function fillPermittedOrderERC1155(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        address to,
        uint256 nonce,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external returns (uint256 quantityFilled, bool isError);

    function fillPermittedOrderERC20(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        address owner,
        address to,
        uint256 nonce,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external returns (uint256 quantityFilled, bool isError);

    function closePermittedOrder(
        address owner,
        address operator,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId
    ) external;

    function allowance(
        address owner, 
        address operator, 
        uint256 tokenType,
        address token, 
        uint256 id,
        bytes32 orderId
    ) external view returns (uint256 amount, uint256 expiration);


    /**
     * =================================================
     * ================ Nonce Management ===============
     * =================================================
     */
    function invalidateUnorderedNonce(uint256 nonce) external;

    function isValidUnorderedNonce(address owner, uint256 nonce) external view returns (bool isValid);

    function lockdown() external;

    function masterNonce(address owner) external view returns (uint256);

    /**
     * =================================================
     * ============== Transfer Functions ===============
     * =================================================
     */
    function transferFromERC721(
        address from,
        address to,
        address token,
        uint256 id
    ) external returns (bool isError);

    function transferFromERC1155(
        address from,
        address to,
        address token,
        uint256 id,
        uint256 amount
    ) external returns (bool isError);

    function transferFromERC20(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool isError);

    /**
     * =================================================
     * ============ Signature Verification =============
     * =================================================
     */
    function domainSeparatorV4() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {SINGLE_USE_PERMIT_TYPEHASH, UPDATE_APPROVAL_TYPEHASH} from "../Constants.sol";

library PermitHash {
    /**
     * @notice  Hashes the permit data for a stored approval
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param amount              The amount authorized by the owner signature
     * @param nonce               The nonce for the permit
     * @param operator            The account that is allowed to use the permit
     * @param approvalExpiration  The time the permit approval expires
     * @param sigDeadline         The deadline for submitting the permit onchain
     * @param masterNonce         The signers master nonce
     *
     * @return hash  The hash of the permit data
     */
    function hashOnChainApproval(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        uint256 nonce,
        address operator,
        uint256 approvalExpiration,
        uint256 sigDeadline,
        uint256 masterNonce
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                UPDATE_APPROVAL_TYPEHASH,
                tokenType,
                token,
                id,
                amount,
                nonce,
                operator,
                approvalExpiration,
                sigDeadline,
                masterNonce
            )
        );
    }

    /**
     * @notice  Hashes the permit data with the single user permit without additional data typehash
     *
     * @param tokenType               The type of token
     * @param token                   The address of the token
     * @param id                      The id of the token
     * @param amount                  The amount authorized by the owner signature
     * @param nonce                   The nonce for the permit
     * @param expiration              The time the permit expires
     * @param masterNonce             The signers master nonce
     *
     * @return hash  The hash of the permit data
     */
    function hashSingleUsePermit(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        uint256 nonce,
        uint256 expiration,
        uint256 masterNonce
    ) internal view returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                SINGLE_USE_PERMIT_TYPEHASH, tokenType, token, id, amount, nonce, msg.sender, expiration, masterNonce
            )
        );
    }

    /**
     * @notice  Hashes the permit data with the supplied typehash
     *
     * @param tokenType               The type of token
     * @param token                   The address of the token
     * @param id                      The id of the token
     * @param amount                  The amount authorized by the owner signature
     * @param nonce                   The nonce for the permit
     * @param expiration              The time the permit expires
     * @param additionalData          The additional data to validate with the permit signature
     * @param additionalDataTypeHash  The typehash of the permit to use for validating the signature
     * @param masterNonce             The signers master nonce
     *
     * @return hash  The hash of the permit data with the supplied typehash
     */
    function hashSingleUsePermitWithAdditionalData(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        uint256 nonce,
        uint256 expiration,
        bytes32 additionalData,
        bytes32 additionalDataTypeHash,
        uint256 masterNonce
    ) internal view returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                additionalDataTypeHash,
                tokenType,
                token,
                id,
                amount,
                nonce,
                msg.sender,
                expiration,
                masterNonce,
                additionalData
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    error Ownable__CallerIsNotOwner();
    error Ownable__NewOwnerIsZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if(owner() != _msgSender()) revert Ownable__CallerIsNotOwner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0)) revert Ownable__NewOwnerIsZeroAddress();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Errors.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Ownable} from "./openzeppelin-optimized/Ownable.sol";
import {EIP712} from "./openzeppelin-optimized/EIP712.sol";
import {
    ZERO_BYTES32,
    ZERO,
    ONE,
    ORDER_STATE_OPEN,
    ORDER_STATE_FILLED,
    ORDER_STATE_CANCELLED,
    SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB,
    PERMIT_ORDER_ADVANCED_TYPEHASH_STUB,
    UPPER_BIT_MASK,
    TOKEN_TYPE_ERC1155,
    TOKEN_TYPE_ERC20,
    TOKEN_TYPE_ERC721,
    PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721,
    PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155,
    PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20,
    PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721,
    PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155,
    PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20,
    PAUSABLE_ORDER_TRANSFER_FROM_ERC1155,
    PAUSABLE_ORDER_TRANSFER_FROM_ERC20
} from "./Constants.sol";
import {PackedApproval, OrderFillAmounts} from "./DataTypes.sol";
import {PermitHash} from "./libraries/PermitHash.sol";
import {IPermitC} from "./interfaces/IPermitC.sol";
import {CollateralizedPausableFlags} from "./CollateralizedPausableFlags.sol";

/*
                                                     @@@@@@@@@@@@@@             
                                                    @@@@@@@@@@@@@@@@@@(         
                                                   @@@@@@@@@@@@@@@@@@@@@        
                                                  @@@@@@@@@@@@@@@@@@@@@@@@      
                                                           #@@@@@@@@@@@@@@      
                                                               @@@@@@@@@@@@     
                            @@@@@@@@@@@@@@*                    @@@@@@@@@@@@     
                           @@@@@@@@@@@@@@@     @               @@@@@@@@@@@@     
                          @@@@@@@@@@@@@@@     @                @@@@@@@@@@@      
                         @@@@@@@@@@@@@@@     @@               @@@@@@@@@@@@      
                        @@@@@@@@@@@@@@@     #@@             @@@@@@@@@@@@/       
                        @@@@@@@@@@@@@@.     @@@@@@@@@@@@@@@@@@@@@@@@@@@         
                       @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@            
                      @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@             
                     @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@           
                    @@@@@@@@@@@@@@@     @@@@@&%%%%%%%%&&@@@@@@@@@@@@@@          
                    @@@@@@@@@@@@@@      @@@@@               @@@@@@@@@@@         
                   @@@@@@@@@@@@@@@     @@@@@                 @@@@@@@@@@@        
                  @@@@@@@@@@@@@@@     @@@@@@                 @@@@@@@@@@@        
                 @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@        
                @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@&        
                @@@@@@@@@@@@@@     *@@@@@@@               (@@@@@@@@@@@@         
               @@@@@@@@@@@@@@@     @@@@@@@@             @@@@@@@@@@@@@@          
              @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           
             @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            
            @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              
           .@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
           @@@@@@@@@@@@@@%     @@@@@@@@@@@@@@@@@@@@@@@@(                        
          @@@@@@@@@@@@@@@                                                       
         @@@@@@@@@@@@@@@                                                        
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                                          
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                           
 
* @title PermitC
* @custom:version 1.0.0
* @author Limit Break, Inc.
* @description Advanced approval management for ERC20, ERC721 and ERC1155 tokens
*              allowing for single use permit transfers, time-bound approvals
*              and order ID based transfers.
*/
contract PermitC is Ownable, CollateralizedPausableFlags, EIP712, IPermitC {
    /**
     * @notice Map of approval details for the provided bytes32 hash to allow for multiple accessors
     *
     * @dev    keccak256(abi.encode(owner, tokenType, token, id, orderId, masterNonce)) =>
     * @dev        operator => (state, amount, expiration)
     * @dev    Utilized for stored approvals by an owner's direct call to `approve` and
     * @dev    approvals by signature in `updateApprovalBySignature`. Both methods use a
     * @dev    bytes32(0) value for the `orderId`.
     */
    mapping(bytes32 => mapping(address => PackedApproval)) internal _transferApprovals;

    /**
     * @notice Map of approval details for the provided bytes32 hash to allow for multiple accessors
     *
     * @dev    keccak256(abi.encode(owner, tokenType, token, id, orderId, masterNonce)) =>
     * @dev        operator => (state, amount, expiration)
     * @dev    Utilized for order approvals by `fillPermittedOrderERC20` and `fillPermittedOrderERC1155`
     * @dev    with the `orderId` provided by the sender.
     */
    mapping(bytes32 => mapping(address => PackedApproval)) internal _orderApprovals;

    /**
     * @notice Map of registered additional data hashes for transfer permits.
     *
     * @dev    This is used to prevent someone from providing an invalid EIP712 envelope label
     * @dev    and tricking a user into signing a different message than they expect.
     */
    mapping(bytes32 => bool) internal _registeredTransferHashes;

    /**
     * @notice Map of registered additional data hashes for order permits.
     *
     * @dev    This is used to prevent someone from providing an invalid EIP712 envelope label
     * @dev    and tricking a user into signing a different message than they expect.
     */
    mapping(bytes32 => bool) internal _registeredOrderHashes;

    /// @dev Map of an address to a bitmap (slot => status)
    mapping(address => mapping(uint256 => uint256)) internal _unorderedNonces;

    /**
     * @notice Master nonce used to invalidate all outstanding approvals for an owner
     *
     * @dev    owner => masterNonce
     * @dev    This is incremented when the owner calls lockdown()
     */
    mapping(address => uint256) internal _masterNonces;

    constructor(
        string memory name,
        string memory version,
        address _defaultContractOwner,
        uint256 _nativeValueToCheckPauseState
    ) CollateralizedPausableFlags(_nativeValueToCheckPauseState) EIP712(name, version) {
        _transferOwnership(_defaultContractOwner);
    }

    /**
     * =================================================
     * ================= Modifiers =====================
     * =================================================
     */
    modifier onlyRegisteredTransferAdvancedTypeHash(bytes32 advancedPermitHash) {
        _requireTransferAdvancedPermitHashIsRegistered(advancedPermitHash);
        _;
    }

    modifier onlyRegisteredOrderAdvancedTypeHash(bytes32 advancedPermitHash) {
        _requireOrderAdvancedPermitHashIsRegistered(advancedPermitHash);
        _;
    }

    /**
     * =================================================
     * ============== Approval Transfers ===============
     * =================================================
     */

    /**
     * @notice Approve an operator to spend a specific token / ID combination
     * @notice This function is compatible with ERC20, ERC721 and ERC1155
     * @notice To give unlimited approval for ERC20 and ERC1155, set amount to type(uint200).max
     * @notice When approving an ERC721, you MUST set amount to `1`
     * @notice When approving an ERC20, you MUST set id to `0`
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Updates the approval for an operator to use an amount of a specific token / ID combination
     * @dev    2. If the expiration is 0, the approval is valid only in the context of the current block
     * @dev    3. If the expiration is not 0, the approval is valid until the expiration timestamp
     * @dev    4. If the provided amount is type(uint200).max, the approval is unlimited
     *
     * @param  tokenType  The type of token being approved - must be 20, 721 or 1155.
     * @param  token      The address of the token contract
     * @param  id         The token ID
     * @param  operator   The address of the operator
     * @param  amount     The amount of tokens to approve
     * @param  expiration The expiration timestamp of the approval
     */
    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external
    {
        _requireValidTokenType(tokenType);
        _storeApproval(tokenType, token, id, amount, expiration, msg.sender, operator);
    }

    /**
     * @notice Use a signed permit to increase the allowance for a provided operator
     * @notice This function is compatible with ERC20, ERC721 and ERC1155
     * @notice To give unlimited approval for ERC20 and ERC1155, set amount to type(uint200).max
     * @notice When approving an ERC721, you MUST set amount to `1`
     * @notice When approving an ERC20, you MUST set id to `0`
     * @notice An `approvalExpiration` of zero is considered an atomic permit which will use the
     * @notice current block time as the expiration time when storing the permit data.
     *
     * @dev    - Throws if the permit has expired
     * @dev    - Throws if the permit's nonce has already been used
     * @dev    - Throws if the permit signature is does not recover to the provided owner
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Updates the approval for an operator to use an amount of a specific token / ID combination
     * @dev    3. Sets the expiration of the approval to the expiration timestamp of the permit
     * @dev    4. If the provided amount is type(uint200).max, the approval is unlimited
     *
     * @param  tokenType            The type of token being approved - must be 20, 721 or 1155.
     * @param  token                Address of the token to approve
     * @param  id                   The token ID
     * @param  nonce                The nonce of the permit
     * @param  amount               The amount of tokens to approve
     * @param  operator             The address of the operator
     * @param  approvalExpiration   The expiration timestamp of the approval
     * @param  sigDeadline          The deadline timestamp for the permit signature
     * @param  owner                The owner of the tokens
     * @param  signedPermit         The permit signature, signed by the owner
     */
    function updateApprovalBySignature(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 nonce,
        uint200 amount,
        address operator,
        uint48 approvalExpiration,
        uint48 sigDeadline,
        address owner,
        bytes calldata signedPermit
    ) external {
        if (block.timestamp > sigDeadline) {
            revert PermitC__ApprovalTransferPermitExpiredOrUnset();
        }
        _requireValidTokenType(tokenType);
        _checkAndInvalidateNonce(owner, nonce);
        _verifyPermitSignature(
            _hashTypedDataV4(
                PermitHash.hashOnChainApproval(
                    tokenType, token, id, amount, nonce, operator, approvalExpiration, sigDeadline, _masterNonces[owner]
                )
            ),
            signedPermit,
            owner
        );

        // Expiration of zero is considered an atomic permit which is only valid in the
        // current block.
        approvalExpiration = approvalExpiration == 0 ? uint48(block.timestamp) : approvalExpiration;

        _storeApproval(tokenType, token, id, amount, approvalExpiration, owner, operator);
    }

    /**
     * @notice Returns the amount of allowance an operator has and it's expiration for a specific token and id
     * @notice If the expiration on the allowance has expired, returns 0
     * @notice To retrieve allowance for ERC20, set id to `0`
     *
     * @param  owner     The owner of the token
     * @param  operator  The operator of the token
     * @param  tokenType The type of token the allowance is for
     * @param  token     The address of the token contract
     * @param  id        The token ID
     *
     * @return allowedAmount The amount of allowance the operator has
     * @return expiration    The expiration timestamp of the allowance
     */
    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration)
    {
        return _allowance(_transferApprovals, owner, operator, tokenType, token, id, ZERO_BYTES32);
    }

    /**
     * =================================================
     * ================ Signed Transfers ===============
     * =================================================
     */

    /**
     * @notice Registers the combination of a provided string with the `SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB`
     * @notice and `PERMIT_ORDER_ADVANCED_TYPEHASH_STUB` to create valid additional data hashes
     *
     * @dev    This function prevents malicious actors from changing the label of the EIP712 hash
     * @dev    to a value that would fool an external user into signing a different message.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The provided string is combined with the `SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB` string
     * @dev    2. The combined string is hashed using keccak256
     * @dev    3. The resulting hash is added to the `_registeredTransferHashes` mapping
     * @dev    4. The provided string is combined with the `PERMIT_ORDER_ADVANCED_TYPEHASH_STUB` string
     * @dev    5. The combined string is hashed using keccak256
     * @dev    6. The resulting hash is added to the `_registeredOrderHashes` mapping
     *
     * @param  additionalDataTypeString The string to register as a valid additional data hash
     */
    function registerAdditionalDataHash(string calldata additionalDataTypeString) external {
        _registeredTransferHashes[keccak256(
            bytes(string.concat(SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB, additionalDataTypeString))
        )] = true;

        _registeredOrderHashes[keccak256(
            bytes(string.concat(PERMIT_ORDER_ADVANCED_TYPEHASH_STUB, additionalDataTypeString))
        )] = true;
    }

    /**
     * @notice Transfer an ERC721 token from the owner to the recipient using a permit signature.
     *
     * @dev    Be advised that the permitted amount for ERC721 is always inferred to be 1, so signed permitted amount
     * @dev    MUST always be set to 1.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the nonce has already been used
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount exceeds the permitted amount
     * @dev    - Throws if the provided token address does not implement ERC721 transferFrom function
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token from the owner to the recipient
     * @dev    2. The nonce of the permit is marked as used
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param token         The address of the token
     * @param id            The ID of the token
     * @param nonce         The nonce of the permit
     * @param expiration    The expiration timestamp of the permit
     * @param owner         The owner of the token
     * @param to            The address to transfer the tokens to
     * @param signedPermit  The permit signature, signed by the owner
     *
     * @return isError      True if the transfer failed, false otherwise
     */
    function permitTransferFromERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes calldata signedPermit
    ) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721);

        _checkPermitApproval(TOKEN_TYPE_ERC721, token, id, ONE, nonce, expiration, owner, ONE, signedPermit);
        isError = _transferFromERC721(owner, to, token, id);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfers an ERC721 token from the owner to the recipient using a permit signature
     * @notice This function includes additional data to verify on the signature, allowing
     * @notice protocols to extend the validation in one function call. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    Be advised that the permitted amount for ERC721 is always inferred to be 1, so signed permitted amount
     * @dev    MUST always be set to 1.
     *
     * @dev    - Throws for any reason permitTransferFromERC721 would.
     * @dev    - Throws if the additional data does not match the signature
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Throws if the provided hash does not match the provided additional data
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token from the owner to the recipient
     * @dev    2. Performs any additional checks in the before and after hooks
     * @dev    3. The nonce of the permit is marked as used
     *
     * @param  token                    The address of the token
     * @param  id                       The ID of the token
     * @param  nonce                    The nonce of the permit
     * @param  expiration               The expiration timestamp of the permit
     * @param  owner                    The owner of the token
     * @param  to                       The address to transfer the tokens to
     * @param  additionalData           The additional data to verify on the signature
     * @param  advancedPermitHash       The hash of the additional data
     * @param  signedPermit             The permit signature, signed by the owner
     *
     * @return isError                  True if the transfer failed, false otherwise
     */
    function permitTransferFromWithAdditionalDataERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external onlyRegisteredTransferAdvancedTypeHash(advancedPermitHash) returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721);

        _checkPermitApprovalWithAdditionalDataERC721(
            token, id, ONE, nonce, expiration, owner, ONE, signedPermit, additionalData, advancedPermitHash
        );
        isError = _transferFromERC721(owner, to, token, id);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfer an ERC1155 token from the owner to the recipient using a permit signature
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the nonce has already been used
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount exceeds the permitted amount
     * @dev    - Throws if the provided token address does not implement ERC1155 safeTransferFrom function
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. The nonce of the permit is marked as used
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param token           The address of the token
     * @param id              The ID of the token
     * @param nonce           The nonce of the permit
     * @param permitAmount    The amount of tokens permitted by the owner
     * @param expiration      The expiration timestamp of the permit
     * @param owner           The owner of the token
     * @param to              The address to transfer the tokens to
     * @param transferAmount  The amount of tokens to transfer
     * @param signedPermit    The permit signature, signed by the owner
     *
     * @return isError        True if the transfer failed, false otherwise
     */
    function permitTransferFromERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155);

        _checkPermitApproval(
            TOKEN_TYPE_ERC1155, token, id, permitAmount, nonce, expiration, owner, transferAmount, signedPermit
        );
        isError = _transferFromERC1155(token, owner, to, id, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfers a token from the owner to the recipient using a permit signature
     * @notice This function includes additional data to verify on the signature, allowing
     * @notice protocols to extend the validation in one function call. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    - Throws for any reason permitTransferFrom would.
     * @dev    - Throws if the additional data does not match the signature
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Throws if the provided hash does not match the provided additional data
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Performs any additional checks in the before and after hooks
     * @dev    3. The nonce of the permit is marked as used
     *
     * @param  token                    The address of the token
     * @param  id                       The ID of the token
     * @param  nonce                    The nonce of the permit
     * @param  permitAmount             The amount of tokens permitted by the owner
     * @param  expiration               The expiration timestamp of the permit
     * @param  owner                    The owner of the token
     * @param  to                       The address to transfer the tokens to
     * @param  transferAmount           The amount of tokens to transfer
     * @param  additionalData           The additional data to verify on the signature
     * @param  advancedPermitHash       The hash of the additional data
     * @param  signedPermit             The permit signature, signed by the owner
     *
     * @return isError                  True if the transfer failed, false otherwise
     */
    function permitTransferFromWithAdditionalDataERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external onlyRegisteredTransferAdvancedTypeHash(advancedPermitHash) returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155);

        _checkPermitApprovalWithAdditionalDataERC1155(
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );

        // copy id to top of stack to avoid stack too deep
        uint256 tmpId = id;
        isError = _transferFromERC1155(token, owner, to, tmpId, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfer an ERC20 token from the owner to the recipient using a permit signature.
     *
     * @dev    Be advised that the token ID for ERC20 is always inferred to be 0, so signed token ID
     * @dev    MUST always be set to 0.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the nonce has already been used
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount exceeds the permitted amount
     * @dev    - Throws if the provided token address does not implement ERC20 transferFrom function
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token in the requested amount from the owner to the recipient
     * @dev    2. The nonce of the permit is marked as used
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param token         The address of the token
     * @param nonce         The nonce of the permit
     * @param permitAmount  The amount of tokens permitted by the owner
     * @param expiration    The expiration timestamp of the permit
     * @param owner         The owner of the token
     * @param to            The address to transfer the tokens to
     * @param signedPermit  The permit signature, signed by the owner
     *
     * @return isError      True if the transfer failed, false otherwise
     */
    function permitTransferFromERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20);

        _checkPermitApproval(
            TOKEN_TYPE_ERC20, token, ZERO, permitAmount, nonce, expiration, owner, transferAmount, signedPermit
        );
        isError = _transferFromERC20(token, owner, to, ZERO, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfers an ERC20 token from the owner to the recipient using a permit signature
     * @notice This function includes additional data to verify on the signature, allowing
     * @notice protocols to extend the validation in one function call. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    Be advised that the token ID for ERC20 is always inferred to be 0, so signed token ID
     * @dev    MUST always be set to 0.
     *
     * @dev    - Throws for any reason permitTransferFromERC20 would.
     * @dev    - Throws if the additional data does not match the signature
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Throws if the provided hash does not match the provided additional data
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Performs any additional checks in the before and after hooks
     * @dev    3. The nonce of the permit is marked as used
     *
     * @param  token                    The address of the token
     * @param  nonce                    The nonce of the permit
     * @param  permitAmount             The amount of tokens permitted by the owner
     * @param  expiration               The expiration timestamp of the permit
     * @param  owner                    The owner of the token
     * @param  to                       The address to transfer the tokens to
     * @param  transferAmount           The amount of tokens to transfer
     * @param  additionalData           The additional data to verify on the signature
     * @param  advancedPermitHash       The hash of the additional data
     * @param  signedPermit             The permit signature, signed by the owner
     *
     * @return isError                  True if the transfer failed, false otherwise
     */
    function permitTransferFromWithAdditionalDataERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external onlyRegisteredTransferAdvancedTypeHash(advancedPermitHash) returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20);

        _checkPermitApprovalWithAdditionalDataERC20(
            token,
            ZERO,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
        isError = _transferFromERC20(token, owner, to, ZERO, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Returns true if the provided hash has been registered as a valid additional data hash for transfers.
     *
     * @param  hash The hash to check
     *
     * @return isRegistered true if the hash is valid, false otherwise
     */
    function isRegisteredTransferAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered) {
        isRegistered = _registeredTransferHashes[hash];
    }

    /**
     * @notice Returns true if the provided hash has been registered as a valid additional data hash for orders.
     *
     * @param  hash The hash to check
     *
     * @return isRegistered true if the hash is valid, false otherwise
     */
    function isRegisteredOrderAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered) {
        isRegistered = _registeredOrderHashes[hash];
    }

    /**
     * =================================================
     * =============== Order Transfers =================
     * =================================================
     */

    /**
     * @notice Transfers an ERC1155 token from the owner to the recipient using a permit signature
     * @notice Order transfers are used to transfer a specific amount of a token from a specific order
     * @notice and allow for multiple uses of the same permit up to the allocated amount. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount + amount already filled exceeds the permitted amount
     * @dev    - Throws if the requested amount is less than the minimum fill amount
     * @dev    - Throws if the provided token address does not implement ERC1155 safeTransferFrom function
     * @dev    - Throws if the provided advanced permit hash has not been registered
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Updates the amount filled for the order ID
     * @dev    3. If completely filled, marks the order as filled
     *
     * @param  signedPermit         The permit signature, signed by the owner
     * @param  orderFillAmounts     The amount of tokens to transfer
     * @param  token                The address of the token
     * @param  id                   The ID of the token
     * @param  owner                The owner of the token
     * @param  to                   The address to transfer the tokens to
     * @param  salt                 The salt of the permit
     * @param  expiration           The expiration timestamp of the permit
     * @param  orderId              The order ID
     * @param  advancedPermitHash   The hash of the additional data
     *
     * @return quantityFilled       The amount of tokens filled
     * @return isError              True if the transfer failed, false otherwise
     */
    function fillPermittedOrderERC1155(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        address to,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external onlyRegisteredOrderAdvancedTypeHash(advancedPermitHash) returns (uint256 quantityFilled, bool isError) {
        _requireNotPaused(PAUSABLE_ORDER_TRANSFER_FROM_ERC1155);

        PackedApproval storage orderStatus = _checkOrderTransferERC1155(
            signedPermit, orderFillAmounts, token, id, owner, salt, expiration, orderId, advancedPermitHash
        );

        (quantityFilled, isError) =
            _orderTransfer(orderStatus, orderFillAmounts, token, id, owner, to, orderId, _transferFromERC1155);

        if (isError) {
            _restoreFillableItems(orderStatus, owner, orderId, quantityFilled, true);
        }
    }

    /**
     * @notice Transfers an ERC20 token from the owner to the recipient using a permit signature
     * @notice Order transfers are used to transfer a specific amount of a token from a specific order
     * @notice and allow for multiple uses of the same permit up to the allocated amount. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount + amount already filled exceeds the permitted amount
     * @dev    - Throws if the requested amount is less than the minimum fill amount
     * @dev    - Throws if the provided token address does not implement ERC20 transferFrom function
     * @dev    - Throws if the provided advanced permit hash has not been registered
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Updates the amount filled for the order ID
     * @dev    3. If completely filled, marks the order as filled
     *
     * @param  signedPermit         The permit signature, signed by the owner
     * @param  orderFillAmounts     The amount of tokens to transfer
     * @param  token                The address of the token
     * @param  owner                The owner of the token
     * @param  to                   The address to transfer the tokens to
     * @param  salt                 The salt of the permit
     * @param  expiration           The expiration timestamp of the permit
     * @param  orderId              The order ID
     * @param  advancedPermitHash   The hash of the additional data
     *
     * @return quantityFilled       The amount of tokens filled
     * @return isError              True if the transfer failed, false otherwise
     */
    function fillPermittedOrderERC20(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        address owner,
        address to,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external onlyRegisteredOrderAdvancedTypeHash(advancedPermitHash) returns (uint256 quantityFilled, bool isError) {
        _requireNotPaused(PAUSABLE_ORDER_TRANSFER_FROM_ERC20);

        PackedApproval storage orderStatus = _checkOrderTransferERC20(
            signedPermit, orderFillAmounts, token, ZERO, owner, salt, expiration, orderId, advancedPermitHash
        );

        (quantityFilled, isError) =
            _orderTransfer(orderStatus, orderFillAmounts, token, ZERO, owner, to, orderId, _transferFromERC20);

        if (isError) {
            _restoreFillableItems(orderStatus, owner, orderId, quantityFilled, true);
        }
    }

    /**
     * @notice Closes an outstanding order to prevent further execution of transfers.
     *
     * @dev    - Throws if the order is not in the open state
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Marks the order as cancelled
     * @dev    2. Sets the order amount to 0
     * @dev    3. Sets the order expiration to 0
     * @dev    4. Emits a OrderClosed event
     *
     * @param  owner      The owner of the token
     * @param  operator   The operator allowed to transfer the token
     * @param  tokenType  The type of token the order is for - must be 20, 721 or 1155.
     * @param  token      The address of the token contract
     * @param  id         The token ID
     * @param  orderId    The order ID
     */
    function closePermittedOrder(
        address owner,
        address operator,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId
    ) external {
        if (!(msg.sender == owner || msg.sender == operator)) {
            revert PermitC__CallerMustBeOwnerOrOperator();
        }
        _requireValidTokenType(tokenType);
        PackedApproval storage orderStatus =
            _getPackedApprovalPtr(_orderApprovals, owner, tokenType, token, id, orderId, operator);

        if (orderStatus.state == ORDER_STATE_OPEN) {
            orderStatus.state = ORDER_STATE_CANCELLED;
            orderStatus.amount = 0;
            orderStatus.expiration = 0;
            emit OrderClosed(orderId, owner, operator, true);
        } else {
            revert PermitC__OrderIsEitherCancelledOrFilled();
        }
    }

    /**
     * @notice Returns the amount of allowance an operator has for a specific token and id
     * @notice If the expiration on the allowance has expired, returns 0
     *
     * @dev    Overload of the on chain allowance function for approvals with a specified order ID
     *
     * @param  owner    The owner of the token
     * @param  operator The operator of the token
     * @param  token    The address of the token contract
     * @param  id       The token ID
     *
     * @return allowedAmount The amount of allowance the operator has
     */
    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id, bytes32 orderId)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration)
    {
        return _allowance(_orderApprovals, owner, operator, tokenType, token, id, orderId);
    }

    /**
     * =================================================
     * ================ Nonce Management ===============
     * =================================================
     */

    /**
     * @notice Invalidates the provided nonce
     *
     * @dev    - Throws if the provided nonce has already been used
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Sets the provided nonce as used for the sender
     *
     * @param  nonce Nonce to invalidate
     */
    function invalidateUnorderedNonce(uint256 nonce) external {
        _checkAndInvalidateNonce(msg.sender, nonce);
    }

    /**
     * @notice Returns if the provided nonce has been used
     *
     * @param  owner The owner of the token
     * @param  nonce The nonce to check
     *
     * @return isValid true if the nonce is valid, false otherwise
     */
    function isValidUnorderedNonce(address owner, uint256 nonce) external view returns (bool isValid) {
        isValid = ((_unorderedNonces[owner][uint248(nonce >> 8)] >> uint8(nonce)) & ONE) == ZERO;
    }

    /**
     * @notice Revokes all outstanding approvals for the sender
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Increments the master nonce for the sender
     * @dev    2. All outstanding approvals for the sender are invalidated
     */
    function lockdown() external {
        unchecked {
            _masterNonces[msg.sender]++;
        }

        emit Lockdown(msg.sender);
    }

    /**
     * @notice Returns the master nonce for the provided owner address
     *
     * @param  owner The owner address
     *
     * @return The master nonce
     */
    function masterNonce(address owner) external view returns (uint256) {
        return _masterNonces[owner];
    }

    /**
     * =================================================
     * ============== Transfer Functions ===============
     * =================================================
     */

    /**
     * @notice Transfer an ERC721 token from the owner to the recipient using on chain approvals
     *
     * @dev    Public transfer function overload for approval transfers
     * @dev    - Throws if the provided token address does not implement ERC721 transferFrom function
     * @dev    - Throws if the requested amount exceeds the approved amount
     * @dev    - Throws if the approval is expired
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Decrements the approval amount by the requested amount
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param  owner    The owner of the token
     * @param  to       The recipient of the token
     * @param  token    The address of the token
     * @param  id       The id of the token
     *
     * @return isError  True if the transfer failed, false otherwise
     */
    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721);

        PackedApproval storage approval = _checkAndUpdateApproval(owner, TOKEN_TYPE_ERC721, token, id, ONE, true);
        isError = _transferFromERC721(owner, to, token, id);

        if (isError) {
            _restoreFillableItems(approval, owner, ZERO_BYTES32, ONE, false);
        }
    }

    /**
     * @notice Transfer an ERC1155 token from the owner to the recipient using on chain approvals
     *
     * @dev    Public transfer function overload for approval transfers
     * @dev    - Throws if the provided token address does not implement ERC1155 safeTransferFrom function
     * @dev    - Throws if the requested amount exceeds the approved amount
     * @dev    - Throws if the approval is expired
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Decrements the approval amount by the requested amount
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param  owner     The owner of the token
     * @param  to       The recipient of the token
     * @param  amount   The amount of the token to transfer
     * @param  token    The address of the token
     * @param  id       The id of the token
     *
     * @return isError  True if the transfer failed, false otherwise
     */
    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError)
    {
        _requireNotPaused(PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155);

        PackedApproval storage approval = _checkAndUpdateApproval(owner, TOKEN_TYPE_ERC1155, token, id, amount, false);
        isError = _transferFromERC1155(token, owner, to, id, amount);

        if (isError) {
            _restoreFillableItems(approval, owner, ZERO_BYTES32, amount, false);
        }
    }

    /**
     * @notice Transfer an ERC20 token from the owner to the recipient using on chain approvals
     *
     * @dev    Public transfer function overload for approval transfers
     * @dev    - Throws if the provided token address does not implement ERC20 transferFrom function
     * @dev    - Throws if the requested amount exceeds the approved amount
     * @dev    - Throws if the approval is expired
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Decrements the approval amount by the requested amount
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param  owner     The owner of the token
     * @param  to       The recipient of the token
     * @param  amount   The amount of the token to transfer
     * @param  token    The address of the token
     *
     * @return isError  True if the transfer failed, false otherwise
     */
    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError)
    {
        _requireNotPaused(PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20);

        PackedApproval storage approval = _checkAndUpdateApproval(owner, TOKEN_TYPE_ERC20, token, ZERO, amount, false);
        isError = _transferFromERC20(token, owner, to, ZERO, amount);

        if (isError) {
            _restoreFillableItems(approval, owner, ZERO_BYTES32, amount, false);
        }
    }

    /**
     * @notice  Performs a transfer of an ERC721 token.
     *
     * @dev     Will **NOT** attempt transfer if `_beforeTransferFrom` hook returns false.
     * @dev     Will **NOT** revert if the transfer is unsucessful.
     * @dev     Invokers **MUST** check `isError` return value to determine success.
     *
     * @param owner  The owner of the token being transferred
     * @param to     The address to transfer the token to
     * @param token  The token address of the token being transferred
     * @param id     The token id being transferred
     *
     * @return isError True if the token was not transferred, false if token was transferred
     */
    function _transferFromERC721(address owner, address to, address token, uint256 id)
        internal
        returns (bool isError)
    {
        isError = _beforeTransferFrom(TOKEN_TYPE_ERC721, token, owner, to, id, ONE);

        if (!isError) {
            try IERC721(token).transferFrom(owner, to, id) {}
            catch {
                isError = true;
            }
        }
    }

    /**
     * @notice  Performs a transfer of an ERC1155 token.
     *
     * @dev     Will **NOT** attempt transfer if `_beforeTransferFrom` hook returns false.
     * @dev     Will **NOT** revert if the transfer is unsucessful.
     * @dev     Invokers **MUST** check `isError` return value to determine success.
     *
     * @param token  The token address of the token being transferred
     * @param owner  The owner of the token being transferred
     * @param to     The address to transfer the token to
     * @param id     The token id being transferred
     * @param amount The quantity of token id to transfer
     *
     * @return isError True if the token was not transferred, false if token was transferred
     */
    function _transferFromERC1155(address token, address owner, address to, uint256 id, uint256 amount)
        internal
        returns (bool isError)
    {
        isError = _beforeTransferFrom(TOKEN_TYPE_ERC1155, token, owner, to, id, amount);

        if (!isError) {
            try IERC1155(token).safeTransferFrom(owner, to, id, amount, "") {}
            catch {
                isError = true;
            }
        }
    }

    /**
     * @notice  Performs a transfer of an ERC20 token.
     *
     * @dev     Will **NOT** attempt transfer if `_beforeTransferFrom` hook returns false.
     * @dev     Will **NOT** revert if the transfer is unsucessful.
     * @dev     Invokers **MUST** check `isError` return value to determine success.
     *
     * @param token  The token address of the token being transferred
     * @param owner  The owner of the token being transferred
     * @param to     The address to transfer the token to
     * @param amount The quantity of token id to transfer
     *
     * @return isError True if the token was not transferred, false if token was transferred
     */
    function _transferFromERC20(address token, address owner, address to, uint256, /*id*/ uint256 amount)
        internal
        returns (bool isError)
    {
        isError = _beforeTransferFrom(TOKEN_TYPE_ERC20, token, owner, to, ZERO, amount);

        if (!isError) {
            (bool success, bytes memory data) =
                token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, owner, to, amount));
            if (!success) {
                isError = true;
            } else if (data.length > 0) {
                isError = !abi.decode(data, (bool));
            }
        }
    }

    /**
     * =================================================
     * ============ Signature Verification =============
     * =================================================
     */

    /**
     * @notice Returns the domain separator used in the permit signature
     *
     * @return domainSeparator The domain separator
     */
    function domainSeparatorV4() external view returns (bytes32 domainSeparator) {
        domainSeparator = _domainSeparatorV4();
    }

    /**
     * @notice  Verifies a permit signature based on the bytes length of the signature provided.
     *
     * @dev     Throws when -
     * @dev         The bytes signature length is 64 or 65 bytes AND
     * @dev         The ECDSA recovered signer is not the owner AND
     * @dev         The owner's code length is zero OR the owner does not return a valid EIP-1271 response
     * @dev
     * @dev         OR
     * @dev
     * @dev         The bytes signature length is not 64 or 65 bytes AND
     * @dev         The owner's code length is zero OR the owner does not return a valid EIP-1271 response
     */
    function _verifyPermitSignature(bytes32 digest, bytes calldata signature, address owner) internal view {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // Divide the signature in r, s and v variables
            /// @solidity memory-safe-assembly
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 32))
                v := byte(0, calldataload(add(signature.offset, 64)))
            }
            (bool isError, address signer) = _ecdsaRecover(digest, v, r, s);
            if (owner != signer || isError) {
                _verifyEIP1271Signature(owner, digest, signature);
            }
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // Divide the signature in r and vs variables
            /// @solidity memory-safe-assembly
            assembly {
                r := calldataload(signature.offset)
                vs := calldataload(add(signature.offset, 32))
            }
            (bool isError, address signer) = _ecdsaRecover(digest, r, vs);
            if (owner != signer || isError) {
                _verifyEIP1271Signature(owner, digest, signature);
            }
        } else {
            _verifyEIP1271Signature(owner, digest, signature);
        }
    }

    /**
     * @notice Verifies an EIP-1271 signature.
     *
     * @dev    Throws when `signer` code length is zero OR the EIP-1271 call does not
     * @dev    return the correct magic value.
     *
     * @param signer     The signer address to verify a signature with
     * @param hash       The hash digest to verify with the signer
     * @param signature  The signature to verify
     */
    function _verifyEIP1271Signature(address signer, bytes32 hash, bytes calldata signature) internal view {
        if (signer.code.length == 0) {
            revert PermitC__SignatureTransferInvalidSignature();
        }

        if (!_safeIsValidSignature(signer, hash, signature)) {
            revert PermitC__SignatureTransferInvalidSignature();
        }
    }

    /**
     * @notice  Overload of the `_ecdsaRecover` function to unpack the `v` and `s` values
     *
     * @param digest    The hash digest that was signed
     * @param r         The `r` value of the signature
     * @param vs        The packed `v` and `s` values of the signature
     *
     * @return isError  True if the ECDSA function is provided invalid inputs
     * @return signer   The recovered address from ECDSA
     */
    function _ecdsaRecover(bytes32 digest, bytes32 r, bytes32 vs)
        internal
        pure
        returns (bool isError, address signer)
    {
        unchecked {
            bytes32 s = vs & UPPER_BIT_MASK;
            uint8 v = uint8(uint256(vs >> 255)) + 27;

            (isError, signer) = _ecdsaRecover(digest, v, r, s);
        }
    }

    /**
     * @notice  Recovers the signer address using ECDSA
     *
     * @dev     Does **NOT** revert if invalid input values are provided or `signer` is recovered as address(0)
     * @dev     Returns an `isError` value in those conditions that is handled upstream
     *
     * @param digest    The hash digest that was signed
     * @param v         The `v` value of the signature
     * @param r         The `r` value of the signature
     * @param s         The `s` value of the signature
     *
     * @return isError  True if the ECDSA function is provided invalid inputs
     * @return signer   The recovered address from ECDSA
     */
    function _ecdsaRecover(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool isError, address signer)
    {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            // Invalid signature `s` value - return isError = true and signer = address(0) to check EIP-1271
            return (true, address(0));
        }

        signer = ecrecover(digest, v, r, s);
        isError = (signer == address(0));
    }

    /**
     * @notice A gas efficient, and fallback-safe way to call the isValidSignature function for EIP-1271.
     *
     * @param signer     The EIP-1271 signer to call to check for a valid signature.
     * @param hash       The hash digest to verify with the EIP-1271 signer.
     * @param signature  The supplied signature to verify.
     *
     * @return isValid   True if the EIP-1271 signer returns the EIP-1271 magic value.
     */
    function _safeIsValidSignature(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        assembly {
            function _callIsValidSignature(_signer, _hash, _signatureOffset, _signatureLength) -> _isValid {
                let ptr := mload(0x40)
                // store isValidSignature(bytes32,bytes) selector
                mstore(ptr, hex"1626ba7e")
                // store bytes32 hash value in abi encoded location
                mstore(add(ptr, 0x04), _hash)
                // store abi encoded location of the bytes signature data
                mstore(add(ptr, 0x24), 0x40)
                // store bytes signature length
                mstore(add(ptr, 0x44), _signatureLength)
                // copy calldata bytes signature to memory
                calldatacopy(add(ptr, 0x64), _signatureOffset, _signatureLength)
                // calculate data length based on abi encoded data with rounded up signature length
                let dataLength := add(0x64, and(add(_signatureLength, 0x1F), not(0x1F)))
                // update free memory pointer
                mstore(0x40, add(ptr, dataLength))

                // static call _signer with abi encoded data
                // skip return data check if call failed or return data size is not at least 32 bytes
                if and(iszero(lt(returndatasize(), 0x20)), staticcall(gas(), _signer, ptr, dataLength, 0x00, 0x20)) {
                    // check if return data is equal to isValidSignature magic value
                    _isValid := eq(mload(0x00), hex"1626ba7e")
                    leave
                }
            }
            isValid := _callIsValidSignature(signer, hash, signature.offset, signature.length)
        }
    }

    /**
     * =================================================
     * ===================== Hooks =====================
     * =================================================
     */

    /**
     * @dev    This function is empty by default. Override it to add additional logic after the approval transfer.
     * @dev    The function returns a boolean value instead of reverting to indicate if there is an error for more granular control in inheriting protocols.
     */
    function _beforeTransferFrom(
        uint256 tokenType,
        address token,
        address owner,
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual returns (bool isError) {}

    /**
     * =================================================
     * ==================== Internal ===================
     * =================================================
     */

    /**
     * @notice Checks if an advanced permit typehash has been registered with PermitC
     *
     * @dev    Throws when the typehash has not been registered
     *
     * @param advancedPermitHash  The permit typehash to check
     */
    function _requireTransferAdvancedPermitHashIsRegistered(bytes32 advancedPermitHash) internal view {
        if (!_registeredTransferHashes[advancedPermitHash]) {
            revert PermitC__SignatureTransferPermitHashNotRegistered();
        }
    }

    /**
     * @notice Checks if an advanced permit typehash has been registered with PermitC
     *
     * @dev    Throws when the typehash has not been registered
     *
     * @param advancedPermitHash  The permit typehash to check
     */
    function _requireOrderAdvancedPermitHashIsRegistered(bytes32 advancedPermitHash) internal view {
        if (!_registeredOrderHashes[advancedPermitHash]) {
            revert PermitC__SignatureTransferPermitHashNotRegistered();
        }
    }

    /**
     * @notice  Invalidates an account nonce if it has not been previously used
     *
     * @dev     Throws when the nonce was previously used
     *
     * @param account  The account to invalidate the nonce of
     * @param nonce    The nonce to invalidate
     */
    function _checkAndInvalidateNonce(address account, uint256 nonce) internal {
        unchecked {
            if (
                uint256(_unorderedNonces[account][uint248(nonce >> 8)] ^= (ONE << uint8(nonce))) & (ONE << uint8(nonce))
                    == ZERO
            ) {
                revert PermitC__NonceAlreadyUsedOrRevoked();
            }
        }
    }

    /**
     * @notice Checks an approval to ensure it is sufficient for the `amount` to send
     *
     * @dev    Throws when the approval is expired
     * @dev    Throws when the approved amount is insufficient
     *
     * @param owner            The owner of the token
     * @param tokenType        The type of token
     * @param token            The address of the token
     * @param id               The id of the token
     * @param amount           The amount to deduct from the approval
     * @param zeroOutApproval  True if the approval should be set to zero
     *
     * @return approval  Storage pointer for the approval data
     */
    function _checkAndUpdateApproval(
        address owner,
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        bool zeroOutApproval
    ) internal returns (PackedApproval storage approval) {
        approval = _getPackedApprovalPtr(_transferApprovals, owner, tokenType, token, id, ZERO_BYTES32, msg.sender);

        if (approval.expiration < block.timestamp) {
            revert PermitC__ApprovalTransferPermitExpiredOrUnset();
        }
        if (approval.amount < amount) {
            revert PermitC__ApprovalTransferExceededPermittedAmount();
        }

        if (zeroOutApproval) {
            approval.amount = 0;
        } else if (approval.amount < type(uint200).max) {
            unchecked {
                approval.amount -= uint200(amount);
            }
        }
    }

    /**
     * @notice  Gets the storage pointer for an approval
     *
     * @param _approvals  The mapping to retrieve the approval from
     * @param account     The account the approval is from
     * @param tokenType   The type of token the approval is for
     * @param token       The address of the token
     * @param id          The id of the token
     * @param orderId     The order id for the approval
     * @param operator    The operator for the approval
     *
     * @return approval  Storage pointer for the approval data
     */
    function _getPackedApprovalPtr(
        mapping(bytes32 => mapping(address => PackedApproval)) storage _approvals,
        address account,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId,
        address operator
    ) internal view returns (PackedApproval storage approval) {
        approval = _approvals[_getPackedApprovalKey(account, tokenType, token, id, orderId)][operator];
    }

    /**
     * @notice  Gets the storage key for the mapping for a specific approval
     *
     * @param owner      The owner of the token
     * @param tokenType  The type of token
     * @param token      The address of the token
     * @param id         The id of the token
     * @param orderId    The order id of the approval
     *
     * @return key  The key value to use to access the approval in the mapping
     */
    function _getPackedApprovalKey(address owner, uint256 tokenType, address token, uint256 id, bytes32 orderId)
        internal
        view
        returns (bytes32 key)
    {
        key = keccak256(abi.encode(owner, tokenType, token, id, orderId, _masterNonces[owner]));
    }

    /**
     * @notice Checks the permit approval for a single use permit without additional data
     *
     * @dev    Throws when the `nonce` has already been consumed
     * @dev    Throws when the permit amount is less than the transfer amount
     * @dev    Throws when the permit is expired
     * @dev    Throws when the signature is invalid
     *
     * @param tokenType       The type of token
     * @param token           The address of the token
     * @param id              The id of the token
     * @param permitAmount    The amount authorized by the owner signature
     * @param nonce           The nonce of the permit
     * @param expiration      The time the permit expires
     * @param owner           The owner of the token
     * @param transferAmount  The amount of tokens requested to transfer
     * @param signedPermit    The signature for the permit
     */
    function _checkPermitApproval(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) internal {
        bytes32 digest = _hashTypedDataV4(
            PermitHash.hashSingleUsePermit(tokenType, token, id, permitAmount, nonce, expiration, _masterNonces[owner])
        );

        _checkPermitData(nonce, expiration, transferAmount, permitAmount, owner, digest, signedPermit);
    }

    /**
     * @notice  Overload of `_checkPermitApprovalWithAdditionalData` to supply TOKEN_TYPE_ERC1155
     *
     * @dev     Prevents stack too deep in `permitTransferFromWithAdditionalDataERC1155`
     * @dev     Throws when the `nonce` has already been consumed
     * @dev     Throws when the permit amount is less than the transfer amount
     * @dev     Throws when the permit is expired
     * @dev     Throws when the signature is invalid
     *
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalDataERC1155(
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        _checkPermitApprovalWithAdditionalData(
            TOKEN_TYPE_ERC1155,
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
    }

    /**
     * @notice  Overload of `_checkPermitApprovalWithAdditionalData` to supply TOKEN_TYPE_ERC20
     *
     * @dev     Prevents stack too deep in `permitTransferFromWithAdditionalDataERC220`
     * @dev     Throws when the `nonce` has already been consumed
     * @dev     Throws when the permit amount is less than the transfer amount
     * @dev     Throws when the permit is expired
     * @dev     Throws when the signature is invalid
     *
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalDataERC20(
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        _checkPermitApprovalWithAdditionalData(
            TOKEN_TYPE_ERC20,
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
    }

    /**
     * @notice  Overload of `_checkPermitApprovalWithAdditionalData` to supply TOKEN_TYPE_ERC721
     *
     * @dev     Prevents stack too deep in `permitTransferFromWithAdditionalDataERC721`
     * @dev     Throws when the `nonce` has already been consumed
     * @dev     Throws when the permit amount is less than the transfer amount
     * @dev     Throws when the permit is expired
     * @dev     Throws when the signature is invalid
     *
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalDataERC721(
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        _checkPermitApprovalWithAdditionalData(
            TOKEN_TYPE_ERC721,
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
    }

    /**
     * @notice Checks the permit approval for a single use permit with additional data
     *
     * @dev    Throws when the `nonce` has already been consumed
     * @dev    Throws when the permit amount is less than the transfer amount
     * @dev    Throws when the permit is expired
     * @dev    Throws when the signature is invalid
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalData(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        bytes32 digest = _getAdvancedTypedDataV4PermitHash(
            tokenType, token, id, permitAmount, owner, nonce, expiration, additionalData, advancedPermitHash
        );

        _checkPermitData(nonce, expiration, transferAmount, permitAmount, owner, digest, signedPermit);
    }

    /**
     * @notice  Checks that a single use permit has not expired, was authorized for the amount
     * @notice  being transferred, has a valid nonce and has a valid signature.
     *
     * @dev    Throws when the `nonce` has already been consumed
     * @dev    Throws when the permit amount is less than the transfer amount
     * @dev    Throws when the permit is expired
     * @dev    Throws when the signature is invalid
     *
     * @param nonce           The nonce of the permit
     * @param expiration      The time the permit expires
     * @param transferAmount  The amount of tokens requested to transfer
     * @param permitAmount    The amount authorized by the owner signature
     * @param owner           The owner of the token
     * @param digest          The digest that was signed by the owner
     * @param signedPermit    The signature for the permit
     */
    function _checkPermitData(
        uint256 nonce,
        uint256 expiration,
        uint256 transferAmount,
        uint256 permitAmount,
        address owner,
        bytes32 digest,
        bytes calldata signedPermit
    ) internal {
        if (block.timestamp > expiration) {
            revert PermitC__SignatureTransferExceededPermitExpired();
        }

        if (transferAmount > permitAmount) {
            revert PermitC__SignatureTransferExceededPermittedAmount();
        }

        _checkAndInvalidateNonce(owner, nonce);
        _verifyPermitSignature(digest, signedPermit, owner);
    }

    /**
     * @notice  Stores an approval for future use by `operator` to move tokens on behalf of `owner`
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param amount              The amount authorized by the owner
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param operator            The account allowed to transfer the tokens
     */
    function _storeApproval(
        uint256 tokenType,
        address token,
        uint256 id,
        uint200 amount,
        uint48 expiration,
        address owner,
        address operator
    ) internal {
        PackedApproval storage approval =
            _getPackedApprovalPtr(_transferApprovals, owner, tokenType, token, id, ZERO_BYTES32, operator);

        approval.expiration = expiration;
        approval.amount = amount;

        emit Approval(owner, token, operator, id, amount, expiration);
    }

    /**
     * @notice  Overload of `_checkOrderTransfer` to supply TOKEN_TYPE_ERC1155
     *
     * @dev     Prevents stack too deep in `fillPermittedOrderERC1155`
     * @dev     Throws when the order start amount is greater than type(uint200).max
     * @dev     Throws when the order status is not open
     * @dev     Throws when the signature is invalid
     * @dev     Throws when the permit is expired
     *
     * @param signedPermit        The signature for the permit
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param salt                The salt value for the permit
     * @param expiration          The time the permit expires
     * @param orderId             The order id for the permit
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return orderStatus  Storage pointer for the approval data
     */
    function _checkOrderTransferERC1155(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) internal returns (PackedApproval storage orderStatus) {
        orderStatus = _checkOrderTransfer(
            signedPermit,
            orderFillAmounts,
            TOKEN_TYPE_ERC1155,
            token,
            id,
            owner,
            salt,
            expiration,
            orderId,
            advancedPermitHash
        );
    }

    /**
     * @notice  Overload of `_checkOrderTransfer` to supply TOKEN_TYPE_ERC20
     *
     * @dev     Prevents stack too deep in `fillPermittedOrderERC20`
     * @dev     Throws when the order start amount is greater than type(uint200).max
     * @dev     Throws when the order status is not open
     * @dev     Throws when the signature is invalid
     * @dev     Throws when the permit is expired
     *
     * @param signedPermit        The signature for the permit
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param salt                The salt value for the permit
     * @param expiration          The time the permit expires
     * @param orderId             The order id for the permit
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return orderStatus  Storage pointer for the approval data
     */
    function _checkOrderTransferERC20(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) internal returns (PackedApproval storage orderStatus) {
        orderStatus = _checkOrderTransfer(
            signedPermit,
            orderFillAmounts,
            TOKEN_TYPE_ERC20,
            token,
            id,
            owner,
            salt,
            expiration,
            orderId,
            advancedPermitHash
        );
    }

    /**
     * @notice  Validates an order transfer to check order start amount, status, signature if not previously
     * @notice  opened, and expiration.
     *
     * @dev     Throws when the order start amount is greater than type(uint200).max
     * @dev     Throws when the order status is not open
     * @dev     Throws when the signature is invalid
     * @dev     Throws when the permit is expired
     *
     * @param signedPermit        The signature for the permit
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param salt                The salt value for the permit
     * @param expiration          The time the permit expires
     * @param orderId             The order id for the permit
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return orderStatus  Storage pointer for the approval data
     */
    function _checkOrderTransfer(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        uint256 tokenType,
        address token,
        uint256 id,
        address owner,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) internal returns (PackedApproval storage orderStatus) {
        if (orderFillAmounts.orderStartAmount > type(uint200).max) {
            revert PermitC__AmountExceedsStorageMaximum();
        }

        orderStatus = _getPackedApprovalPtr(_orderApprovals, owner, tokenType, token, id, orderId, msg.sender);

        if (orderStatus.state == ORDER_STATE_OPEN) {
            if (orderStatus.amount == 0) {
                _verifyPermitSignature(
                    _getAdvancedTypedDataV4PermitHash(
                        tokenType,
                        token,
                        id,
                        orderFillAmounts.orderStartAmount,
                        owner,
                        salt,
                        expiration,
                        orderId,
                        advancedPermitHash
                    ),
                    signedPermit,
                    owner
                );

                orderStatus.amount = uint200(orderFillAmounts.orderStartAmount);
                orderStatus.expiration = expiration;
                emit OrderOpened(orderId, owner, msg.sender, orderFillAmounts.orderStartAmount);
            }

            if (block.timestamp > orderStatus.expiration) {
                revert PermitC__SignatureTransferExceededPermitExpired();
            }
        } else {
            revert PermitC__OrderIsEitherCancelledOrFilled();
        }
    }

    /**
     * @notice  Checks the order fill amounts against approval data and transfers tokens, updates
     * @notice  approval if the fill results in the order being closed.
     *
     * @dev     Throws when the amount to fill is less than the minimum fill amount
     *
     * @param orderStatus         Storage pointer for the approval data
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param to                  The address to send the tokens to
     * @param orderId             The order id for the permit
     * @param _transferFrom       Function pointer of the transfer function to send tokens with
     *
     * @return quantityFilled     The number of tokens filled in the order
     * @return isError            True if there was an error transferring tokens, false otherwise
     */
    function _orderTransfer(
        PackedApproval storage orderStatus,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        address to,
        bytes32 orderId,
        function (address, address, address, uint256, uint256) internal returns (bool) _transferFrom
    ) internal returns (uint256 quantityFilled, bool isError) {
        quantityFilled = orderFillAmounts.requestedFillAmount;

        if (quantityFilled > orderStatus.amount) {
            quantityFilled = orderStatus.amount;
        }

        if (quantityFilled < orderFillAmounts.minimumFillAmount) {
            revert PermitC__UnableToFillMinimumRequestedQuantity();
        }

        unchecked {
            orderStatus.amount -= uint200(quantityFilled);
            emit OrderFilled(orderId, owner, msg.sender, quantityFilled);
        }

        if (orderStatus.amount == 0) {
            orderStatus.state = ORDER_STATE_FILLED;
            emit OrderClosed(orderId, owner, msg.sender, false);
        }

        isError = _transferFrom(token, owner, to, id, quantityFilled);
    }

    /**
     * @notice  Restores an account's nonce when a transfer was not successful
     *
     * @dev     Throws when the nonce was not already consumed
     *
     * @param account  The account to restore the nonce of
     * @param nonce    The nonce to restore
     */
    function _restoreNonce(address account, uint256 nonce) internal {
        unchecked {
            if (
                uint256(_unorderedNonces[account][uint248(nonce >> 8)] ^= (ONE << uint8(nonce))) & (ONE << uint8(nonce))
                    != ZERO
            ) {
                revert PermitC__NonceNotUsedOrRevoked();
            }
        }
    }

    /**
     * @notice  Restores an approval amount when a transfer was not successful
     *
     * @param approval        Storage pointer for the approval data
     * @param owner           The owner of the tokens
     * @param orderId         The order id to restore approval amount on
     * @param unfilledAmount  The amount that was not filled on the order
     * @param isOrderPermit   True if the fill restoration is for an permit order
     */
    function _restoreFillableItems(
        PackedApproval storage approval,
        address owner,
        bytes32 orderId,
        uint256 unfilledAmount,
        bool isOrderPermit
    ) internal {
        if (unfilledAmount > 0) {
            if (isOrderPermit) {
                // Order permits always deduct amount and must be restored
                unchecked {
                    approval.amount += uint200(unfilledAmount);
                }

                approval.state = ORDER_STATE_OPEN;
                emit OrderRestored(orderId, owner, unfilledAmount);
            } else if (approval.amount < type(uint200).max) {
                // Stored approvals only deduct amount
                unchecked {
                    approval.amount += uint200(unfilledAmount);
                }
            }
        }
    }

    function _requireValidTokenType(uint256 tokenType) internal pure {
        if (!(tokenType == TOKEN_TYPE_ERC721 || tokenType == TOKEN_TYPE_ERC1155 || tokenType == TOKEN_TYPE_ERC20)) {
            revert PermitC__InvalidTokenType();
        }
    }

    /**
     * @notice  Generates an EIP-712 digest for a permit
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param amount              The amount authorized by the owner signature
     * @param owner               The owner of the token
     * @param nonce               The nonce for the permit
     * @param expiration          The time the permit expires
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return digest  The EIP-712 digest of the permit data
     */
    function _getAdvancedTypedDataV4PermitHash(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        address owner,
        uint256 nonce,
        uint256 expiration,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal view returns (bytes32 digest) {
        // cache masterNonce on stack to avoid stack too deep
        uint256 masterNonce_ = _masterNonces[owner];
        digest = _hashTypedDataV4(
            PermitHash.hashSingleUsePermitWithAdditionalData(
                tokenType, token, id, amount, nonce, expiration, additionalData, advancedPermitHash, masterNonce_
            )
        );
    }

    /**
     * @notice  Returns the current allowed amount and expiration for a stored permit
     *
     * @dev     Returns zero allowed if the permit has expired
     *
     * @param _approvals  The mapping to retrieve the approval from
     * @param owner       The account the approval is from
     * @param operator    The operator for the approval
     * @param tokenType   The type of token the approval is for
     * @param token       The address of the token
     * @param id          The id of the token
     * @param orderId     The order id for the approval
     *
     * @return allowedAmount  The amount authorized by the approval, zero if the permit has expired
     * @return expiration     The expiration of the approval
     */
    function _allowance(
        mapping(bytes32 => mapping(address => PackedApproval)) storage _approvals,
        address owner,
        address operator,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId
    ) internal view returns (uint256 allowedAmount, uint256 expiration) {
        PackedApproval storage allowed =
            _getPackedApprovalPtr(_approvals, owner, tokenType, token, id, orderId, operator);
        allowedAmount = allowed.expiration < block.timestamp ? 0 : allowed.amount;
        expiration = allowed.expiration;
    }

    /**
     * @notice  Allows the owner of the PermitC contract to access pausable admin functions
     *
     * @dev     May be overriden by an inheriting contract to provide alternative permission structure
     */
    function _requireCallerHasPausePermissions() internal view virtual override {
        _checkOwner();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPearlmit {
    struct SignatureApproval {
        uint256 tokenType; // 20 = ERC20, 721 = ERC721, 1155 = ERC1155.
        address token; // Address of the token.
        uint256 id; // ID of the token (0 if ERC20).
        uint200 amount; // Amount of the token (0 if ERC721).
        address operator; // Address of the operator to transfer the tokens to.
    }

    struct PermitBatchTransferFrom {
        SignatureApproval[] approvals; // Array of SignatureApproval structs.
        address owner; // Address of the owner of the tokens.
        uint256 nonce; // Nonce of the owner.
        uint48 sigDeadline; // Deadline for the signature.
        uint256 masterNonce; // Master nonce of the owner.
        bytes signedPermit; // Signature of the permit. (Not present in the TYPEHASH)
        address executor; // Address of the allowed executor of the permit.
        // In the case of Tapioca, it'll be the `msg.sender` from src chain, checked against `TOE` trusted `srcChainSender`.
        bytes32 hashedData; // Hashed data that comes with the permit execution. See more in Pearlmit.sol.
    }

    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external;

    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration);

    function clearAllowance(address owner, uint256 tokenType, address token, uint256 id) external;

    function permitBatchTransferFrom(PermitBatchTransferFrom calldata batch, bytes32 hashedData)
        external
        returns (bool[] memory errorStatus);

    function permitBatchApprove(PermitBatchTransferFrom calldata batch, bytes32 hashedData) external;

    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {
    PermitC, PermitC__SignatureTransferExceededPermitExpired, PackedApproval, ZERO_BYTES32
} from "permitc/PermitC.sol";

// Tapioca
import {PearlmitHash} from "./PearlmitHash.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title Pearlmit
 * @author Limit Break Inc., Tapioca
 * @notice Pearlmit inherit PermitC and implements a new `permitBatchTransferFrom()` function
 * to allow batch transfer of multiple token types.
 */
contract Pearlmit is PermitC {
    error Pearlmit__BadHashedData();

    constructor(string memory name, string memory version, address owner, uint256 nativeValueToCheckPauseState)
        PermitC(name, version, owner, nativeValueToCheckPauseState)
    {}

    /**
     * @notice Permit batch approve of multiple token types.
     * @dev Check the validity of a permit batch transfer.
     *      - Reverts if the permit is invalid.
     *      - Reverts if the permit is expired.
     * @dev Invalidate the nonce after checking it.
     * @dev If past allowances for the token still exist, bypass the permit check.
     * @dev When performing the hash check, it uses the msg.sender as the expected operator,
     * countering the possibility of grief.
     * @dev If past allowances for the token still exist, bypass the permit check.
     *
     * @param batch PermitBatchTransferFrom struct containing all necessary data for batch transfer.
     * batch.approvals - array of SignatureApproval structs.
     *      * batch.approvals.tokenType - type of token (20 = ERC20, 721 = ERC721, 1155 = ERC1155).
     *      * batch.approvals.token - address of the token.
     *      * batch.approvals.id - id of the token (0 if ERC20).
     *      * batch.approvals.amount - amount of the token (0 if ERC721).
     *      * batch.approvals.operator - address of the operator to transfer the tokens to.
     *      * batch.approvals.approvalExpiration - expiration of the approval.
     * batch.owner - address of the owner of the tokens.
     * batch.nonce - nonce of the owner.
     * batch.sigDeadline - deadline for the signature.
     * batch.signedPermit - signature of the permit.
     *
     * @param hashedData Hashed data that comes with the permit execution. Will be `msg.sender` -> `srcMsgSender` from an LZ perspective.
     * This is useful in an async scenario
     * where the permit is signed to execute some certain actions. The payload can be hashed and used
     * in `hashedData` to trust that the permit is being used for the intended purpose, from the intended executor.
     * The source needs to be trusted to pass a valid `hashedData`, in the case of Pearlmit usage, this'll be
     * a TapiocaOmnichainReceiver contract.
     *
     */
    function permitBatchApprove(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) external {
        _checkPermitBatchApproval(batch, hashedData);

        uint256 numPermits = batch.approvals.length;
        for (uint256 i = 0; i < numPermits; ++i) {
            IPearlmit.SignatureApproval calldata approval = batch.approvals[i];
            _storeApproval(
                approval.tokenType,
                approval.token,
                approval.id,
                approval.amount,
                batch.sigDeadline,
                batch.owner,
                approval.operator
            );
        }
    }

    /**
     * @notice Clear the allowance of an owner if it is called by the approved operator
     */
    function clearAllowance(address owner, uint256 tokenType, address token, uint256 id) external {
        (uint256 allowedAmount,) = _allowance(_transferApprovals, owner, msg.sender, tokenType, token, id, ZERO_BYTES32);
        if (allowedAmount > 0) {
            _clearAllowance(owner, tokenType, token, msg.sender, id);
        }
    }

    /**
     * @dev Clear the allowance of an owner to a given operator by setting the amount to 0 and expiring it.
     */
    function _clearAllowance(address owner, uint256 tokenType, address token, address operator, uint256 id) internal {
        _storeApproval(tokenType, token, id, 0, 0, owner, operator);
    }

    /**
     * @dev Generate the digest and check its validity against the permit.
     * @dev If past allowances for the token still exist, bypass the permit check.
     */
    function _checkPermitBatchApproval(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) internal {
        bytes32 digest = _hashTypedDataV4(PearlmitHash.hashBatchTransferFrom(batch, _masterNonces[batch.owner]));

        if (batch.hashedData != hashedData) {
            revert Pearlmit__BadHashedData();
        }
        _checkBatchPermitData(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }

    /**
     * @dev Check the validity of a permit batch transfer.
     *      - Reverts if the permit is invalid.
     *      - Reverts if the permit is expired.
     * @dev Invalidate the nonce after checking it.
     */
    function _checkBatchPermitData(
        uint256 nonce,
        uint256 expiration,
        address owner,
        bytes32 digest,
        bytes calldata signedPermit
    ) internal {
        if (block.timestamp > expiration) {
            revert PermitC__SignatureTransferExceededPermitExpired();
        }

        _verifyPermitSignature(digest, signedPermit, owner);
        _checkAndInvalidateNonce(owner, nonce);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

library PearlmitHash {
    // Batch transfer
    bytes32 public constant _PERMIT_SIGNATURE_APPROVAL_TYPEHASH =
        keccak256("SignatureApproval(uint256 tokenType,address token,uint256 id,uint200 amount,address operator)");

    // Only `signedPermit` is not present, otherwise should be 1:1 with `IPearlmit.PermitBatchTransferFrom`
    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(SignatureApproval[] approvals,address owner,uint256 nonce,uint48 sigDeadline,uint256 masterNonce,address executor,bytes32 hashedData)SignatureApproval(uint256 tokenType,address token,uint256 id,uint200 amount,address operator)"
    );

    /**
     * @dev Hashes the permit batch transfer from.
     */
    function hashBatchTransferFrom(IPearlmit.PermitBatchTransferFrom calldata batch, uint256 masterNonce)
        internal
        view
        returns (bytes32)
    {
        IPearlmit.SignatureApproval[] memory approvals = batch.approvals;
        uint256 numPermits = approvals.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitSignatureApproval(approvals[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                batch.owner,
                batch.nonce,
                batch.sigDeadline,
                masterNonce,
                msg.sender, // executor
                batch.hashedData
            )
        );
    }

    /**
     * @dev Hashes the permit signature approval.
     */
    function _hashPermitSignatureApproval(IPearlmit.SignatureApproval memory approval)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                approval.tokenType,
                approval.token,
                approval.id,
                approval.amount,
                approval.operator
            )
        );
    }
}