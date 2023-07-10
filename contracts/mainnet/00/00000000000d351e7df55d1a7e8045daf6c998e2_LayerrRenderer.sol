// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ILayerrRenderer} from "./interfaces/ILayerrRenderer.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";

/**
 * @title LayerrRenderer
 * @author 0xth0mas (Layerr)
 * @notice LayerrRenderer handles contractURI and tokenURI generation for contracts
 *         deployed on the Layerr platform. Contract owners have complete control of 
 *         their tokens with the ability to set their own renderer, host their tokens
 *         with Layerr, set all tokens to a prereveal image, or set a base URI that
 *         token ids will be appended to.
 *         Tokens hosted with Layerr will automatically generate a tokenURI with the
 *         `layerrBaseTokenUri`/{chainId}/{contractAddress}/{tokenId} to allow new tokens
 *         to be minted without updating a base uri.
 *         For long term storage, Layerr-hosted tokens can be swept onto Layerr's IPFS
 *         solution.
 */
contract LayerrRenderer is ILayerrRenderer {

    /// @dev Layerr-owned EOA that is allowed to update the base token and base contract URIs for Layerr-hosted non-IPFS tokens
    address public owner;

    /// @dev Layerr's signature account for checking parameters of tokens swept to Layerr IPFS
    address public layerrSigner = 0xc44355A57368C22D01A8a146C0a2669B504B25A0;

    /// @dev The base token URI that chainId, contractAddress and tokenId are added to for rendering
    string public layerrBaseTokenUri = 'https://metadata.layerr.art';

    /// @dev The base contract URI that chainId and contractAddress are added to for rendering
    string public layerrBaseContractUri = 'https://contract-metadata.layerr.art';

    /// @dev The rendering type for a token contract, defaults to LAYERR_HOSTED
    mapping(address => RenderType) public contractRenderType;

    /// @dev Base token URI set by the token contract owner for BASE_PLUS_TOKEN render type and LAYERR_HOSTED tokens on IPFS
    mapping(address => string) public contractBaseTokenUri;

    /// @dev Token contract URI set by the token contract owner
    mapping(address => string) public contractContractUri;

    /// @dev mapping of token contract addresses that flag a token contract as having all of its tokens hosted on Layerr IPFS
    mapping(address => bool) public layerrHostedAllTokensOnIPFS;

    /// @dev bitmap of token ids for a token contract that have been moved to Layerr hosted IPFS
    mapping(address => mapping(uint256 => uint256)) public layerrHostedTokensOnIPFS;

    /// @dev mapping of token contract addresses with the UTC timestamp of when the IPFS hosting is paid through
    mapping(address => uint256) public layerrHostedIPFSExpiration;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotContractOwner();
        }
        _;
    }

    constructor() {
        owner = 0x0000000000799dfE79Ed462822EC68eF9a6199e6;
    }

    /**
     * @inheritdoc ILayerrRenderer
     */
    function tokenURI(
        address contractAddress,
        uint256 tokenId
    ) external view returns (string memory _tokenURI) {
        RenderType renderType = contractRenderType[contractAddress];
        if (renderType == RenderType.LAYERR_HOSTED) {
            if(_isLayerrHostedIPFS(contractAddress, tokenId)) {
                _tokenURI = string(
                    abi.encodePacked(contractBaseTokenUri[contractAddress], _toString(tokenId))
                );
            } else {
                _tokenURI = string(
                    abi.encodePacked(
                        layerrBaseTokenUri,
                        "/",
                        _toString(block.chainid),
                        "/",
                        _toString(contractAddress),
                        "/",
                        _toString(tokenId)
                    )
                );
            }
        } else if (renderType == RenderType.PREREVEAL) {
            _tokenURI = contractBaseTokenUri[contractAddress];
        } else if (renderType == RenderType.BASE_PLUS_TOKEN) {
            _tokenURI = string(
                abi.encodePacked(contractBaseTokenUri[contractAddress], _toString(tokenId))
            );
        }
    }

    /**
     * @inheritdoc ILayerrRenderer
     */
    function contractURI(
        address contractAddress
    ) external view returns (string memory _contractURI) {
        _contractURI = contractContractUri[contractAddress];
        if (bytes(_contractURI).length == 0) {
            _contractURI = string(
                abi.encodePacked(
                    layerrBaseContractUri,
                    "/",
                    _toString(block.chainid),
                    "/",
                    _toString(contractAddress)
                )
            );
        }
    }

    /**
     * @notice Updates rendering settings for a contract. Must be the ERC173 owner for the token contract to call.
     * @param contractAddress address of the contract to set the base token URI for
     * @param baseTokenUri base token URI to set for `contractAddress`
     * @param renderType sets the current render type for the contract
     */
    function setContractBaseTokenUri(
        address contractAddress,
        string calldata baseTokenUri,
        RenderType renderType
    ) external {
        if (IOwnable(contractAddress).owner() != msg.sender) {
            revert NotContractOwner();
        }
        contractBaseTokenUri[contractAddress] = baseTokenUri;
        contractRenderType[contractAddress] = renderType;
    }

    /**
     * @notice Updates rendering settings for a contract. Must be the ERC173 owner for the token contract to call.
     * @param contractAddress address of the contract to set the base token URI for
     * @param contractUri contract URI to set for `contractAddress`
     */
    function setContractUri(
        address contractAddress,
        string calldata contractUri
    ) external {
        if (IOwnable(contractAddress).owner() != msg.sender) {
            revert NotContractOwner();
        }
        contractContractUri[contractAddress] = contractUri;
    }

    /**
     * @notice Updates the base token URI to sweep tokens to IPFS for Layerr hosted tokens
     *         This allows new tokens to continue to be minted on the contract with the default
     *         rendering address while existing tokens are moved onto IPFS for long term storage.
     * @param contractAddress address of the token contract
     * @param baseTokenUri base token URI to set for the contract's tokens
     * @param allTokens set to true for larger collections that are done minting
     *                  avoids setting each token id in the bitmap for gas savings but new tokens
     *                  will not render with the default rendering address
     * @param tokenIds array of token ids that are being swept to Layerr hosted IPFS
     * @param ipfsExpiration UTC timestamp that the IPFS hosting is paid through
     * @param signature signature by Layerr account to confirm the parameters supplied
     */
    function setContractBaseTokenUriForLayerrHostedIPFS(
        address contractAddress,
        string calldata baseTokenUri,
        bool allTokens,
        uint256[] calldata tokenIds,
        uint256 ipfsExpiration,
        bytes calldata signature
    ) external payable {
        if (IOwnable(contractAddress).owner() != msg.sender) {
            revert NotContractOwner();
        }

        bytes32 hash = keccak256(abi.encodePacked(contractAddress, baseTokenUri, ipfsExpiration, msg.value));
        address signer = _recover(hash, signature);
        if(signer != layerrSigner) revert InvalidSignature();

        (bool sent, ) = payable(owner).call{value: msg.value}("");
        if (!sent) {
            revert PaymentFailed();
        }

        layerrHostedIPFSExpiration[contractAddress] = ipfsExpiration;
        layerrHostedAllTokensOnIPFS[contractAddress] = allTokens;
        contractBaseTokenUri[contractAddress] = baseTokenUri;
        contractRenderType[contractAddress] = RenderType.LAYERR_HOSTED;

        for(uint256 i = 0;i < tokenIds.length;) {
            _setLayerrHostedIPFS(contractAddress, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ILayerrRenderer).interfaceId;
    }

    /* OWNER FUNCTIONS */
    
    /**
     * @notice Owner function to set the Layerr signature account
     * @param _layerrSigner address that will be used to check signatures
     */
    function setLayerrSigner(
        address _layerrSigner
    ) external onlyOwner {
        layerrSigner = _layerrSigner;
    }

    /**
     * @notice Owner function to set the default token rendering URI
     * @param _layerrBaseTokenUri base token uri to be used for default token rendering
     */
    function setLayerrBaseTokenUri(
        string calldata _layerrBaseTokenUri
    ) external onlyOwner {
        layerrBaseTokenUri = _layerrBaseTokenUri;
    }

    /**
     * @notice Owner function to set the default contract rendering URI
     * @param _layerrBaseContractUri base contract uri to be used for default rendering
     */

    function setLayerrBaseContractUri(
        string calldata _layerrBaseContractUri
    ) external onlyOwner {
        layerrBaseContractUri = _layerrBaseContractUri;
    }

    /* INTERNAL FUNCTIONS */

    /**
     * @notice Checks to see if a token has been flagged as being hosted on Layerr IPFS
     * @param contractAddress token contract address to check
     * @param tokenId id of the token to check
     * @return isIPFS if token has been flagged as being hosted on Layerr IPFS
     */
    function _isLayerrHostedIPFS(address contractAddress, uint256 tokenId) internal view returns(bool isIPFS) {
        isIPFS = layerrHostedAllTokensOnIPFS[contractAddress] || layerrHostedTokensOnIPFS[contractAddress][tokenId >> 8] & (1 << (tokenId & 0xFF)) != 0;
    }

    /**
     * @notice Flags a token as being hosted on Layerr IPFS in a bitmap
     * @param contractAddress token contract address
     * @param tokenId id of the token
     */
    function _setLayerrHostedIPFS(address contractAddress, uint256 tokenId) internal {
        layerrHostedTokensOnIPFS[contractAddress][tokenId >> 8] |= (1 << (tokenId & 0xFF));
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    function _toString(address value) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; ) {
            bytes1 b = bytes1(uint8(uint(uint160(value)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
            unchecked { ++i; }
        }
        return string(s);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165} from "./IERC165.sol";

/**
 * @title ILayerrRenderer
 * @author 0xth0mas (Layerr)
 * @notice ILayerrRenderer interface defines functions required in LayerrRenderer to be callable by token contracts
 */
interface ILayerrRenderer is ERC165 {

    enum RenderType {
        LAYERR_HOSTED,
        PREREVEAL,
        BASE_PLUS_TOKEN
    }

    /// @dev Thrown when a payment fails for Layerr-hosted IPFS
    error PaymentFailed();

    /// @dev Thrown when a call is made for an owner-function by a non-contract owner
    error NotContractOwner();

    /// @dev Thrown when a signature is not made by the authorized account
    error InvalidSignature();

    /**
     * @notice Generates a tokenURI for the `contractAddress` and `tokenId`
     * @param contractAddress token contract address to render a token URI for
     * @param tokenId token id to render
     * @return uri for the token metadata
     */
    function tokenURI(
        address contractAddress,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @notice Generates a contractURI for the `contractAddress`
     * @param contractAddress contract address to render a contract URI for
     * @return uri for the contract metadata
     */
    function contractURI(
        address contractAddress
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. 
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165} from './IERC165.sol';

interface IOwnable is ERC165 {

    /// @dev Thrown when a non-owner is attempting to perform an owner function
    error NotContractOwner();

    /// @dev Emitted when contract ownership is transferred to a new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view external returns(address);
	
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract    
    function transferOwnership(address _newOwner) external;	
}