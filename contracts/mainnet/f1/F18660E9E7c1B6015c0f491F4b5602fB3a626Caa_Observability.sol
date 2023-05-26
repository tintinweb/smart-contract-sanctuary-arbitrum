// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IObservability.sol";

/**
 * @title Observability
 * @author highlight.xyz
 * @notice Highlight Observability
 * @dev Singleton to coalesce select Highlight protocol events
 */
contract Observability is IObservability {
    /**
     * @notice See {IObservability-emitMinterRegistrationChanged}
     */
    function emitMinterRegistrationChanged(address minter, bool registered) external {
        emit MinterRegistrationChanged(msg.sender, minter, registered);
    }

    /**
     * @notice See {IObservability-emitGranularTokenManagersSet}
     */
    function emitGranularTokenManagersSet(uint256[] calldata _ids, address[] calldata _tokenManagers) external {
        emit GranularTokenManagersSet(msg.sender, _ids, _tokenManagers);
    }

    /**
     * @notice See {IObservability-emitGranularTokenManagersRemoved}
     */
    function emitGranularTokenManagersRemoved(uint256[] calldata _ids) external {
        emit GranularTokenManagersRemoved(msg.sender, _ids);
    }

    /**
     * @notice See {IObservability-emitDefaultTokenManagerChanged}
     */
    function emitDefaultTokenManagerChanged(address newDefaultTokenManager) external {
        emit DefaultTokenManagerChanged(msg.sender, newDefaultTokenManager);
    }

    /**
     * @notice See {IObservability-emitDefaultRoyaltySet}
     */
    function emitDefaultRoyaltySet(address recipientAddress, uint16 royaltyPercentageBPS) external {
        emit DefaultRoyaltySet(msg.sender, recipientAddress, royaltyPercentageBPS);
    }

    /**
     * @notice See {IObservability-emitGranularRoyaltiesSet}
     */
    function emitGranularRoyaltiesSet(uint256[] calldata ids, IRoyaltyManager.Royalty[] calldata _newRoyalties)
        external
    {
        emit GranularRoyaltiesSet(msg.sender, ids, _newRoyalties);
    }

    /**
     * @notice See {IObservability-emitRoyaltyManagerChanged}
     */
    function emitRoyaltyManagerChanged(address newRoyaltyManager) external {
        emit RoyaltyManagerChanged(msg.sender, newRoyaltyManager);
    }

    /**
     * @notice See {IObservability-emitMintsFrozen}
     */
    function emitMintsFrozen() external {
        emit MintsFrozen(msg.sender);
    }

    /**
     * @notice See {IObservability-emitContractMetadataSet}
     */
    function emitContractMetadataSet(
        string calldata name,
        string calldata symbol,
        string calldata contractURI
    ) external {
        emit ContractMetadataSet(msg.sender, name, symbol, contractURI);
    }

    /**
     * @notice See {IObservability-emitHashedMetadataConfigSet}
     */
    function emitHashedMetadataConfigSet(
        bytes calldata hashedURIData,
        bytes calldata hashedRotationData,
        uint256 _supply
    ) external {
        emit HashedMetadataConfigSet(msg.sender, hashedURIData, hashedRotationData, _supply);
    }

    /**
     * @notice See {IObservability-emitRevealed}
     */
    function emitRevealed(bytes calldata key, uint256 newRotationKey) external {
        emit Revealed(msg.sender, key, newRotationKey);
    }

    /**
     * @notice See {IObservability-emitTokenURIsSet}
     */
    function emitTokenURIsSet(uint256[] calldata ids, string[] calldata uris) external {
        emit TokenURIsSet(msg.sender, ids, uris);
    }

    /**
     * @notice See {IObservability-emitLimitSupplySet}
     */
    function emitLimitSupplySet(uint256 newLimitSupply) external {
        emit LimitSupplySet(msg.sender, newLimitSupply);
    }

    /**
     * @notice See {IObservability-emitBaseUriSet}
     */
    function emitBaseUriSet(string calldata newBaseUri) external {
        emit BaseUriSet(msg.sender, newBaseUri);
    }

    /**
     * @notice See {IObservability-emitGenerativeSeriesDeployed}
     */
    function emitGenerativeSeriesDeployed(address contractAddress) external {
        emit GenerativeSeriesDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitSeriesDeployed}
     */
    function emitSeriesDeployed(address contractAddress) external {
        emit SeriesDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitMultipleEditionsDeployed}
     */
    function emitMultipleEditionsDeployed(address contractAddress) external {
        emit MultipleEditionsDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitSingleEditionDeployed}
     */
    function emitSingleEditionDeployed(address contractAddress) external {
        emit SingleEditionDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitTransfer}
     */
    function emitTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        emit Transfer(msg.sender, from, to, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../royaltyManager/interfaces/IRoyaltyManager.sol";

/**
 * @title IObservability
 * @author highlight.xyz
 * @notice Interface to interact with the Highlight observability singleton
 * @dev Singleton to coalesce select Highlight protocol events
 */
interface IObservability {
    /**************************
      ERC721Base / ERC721MinimizedBase events
     **************************/

    /**
     * @notice Emitted when minter is registered or unregistered
     * @param contractAddress Initial contract that emitted event
     * @param minter Minter that was changed
     * @param registered True if the minter was registered, false if unregistered
     */
    event MinterRegistrationChanged(address indexed contractAddress, address indexed minter, bool indexed registered);

    /**
     * @notice Emitted when token managers are set for token/edition ids
     * @param contractAddress Initial contract that emitted event
     * @param _ids Edition / token ids
     * @param _tokenManagers Token managers to set for tokens / editions
     */
    event GranularTokenManagersSet(address indexed contractAddress, uint256[] _ids, address[] _tokenManagers);

    /**
     * @notice Emitted when token managers are removed for token/edition ids
     * @param contractAddress Initial contract that emitted event
     * @param _ids Edition / token ids to remove token managers for
     */
    event GranularTokenManagersRemoved(address indexed contractAddress, uint256[] _ids);

    /**
     * @notice Emitted when default token manager changed
     * @param contractAddress Initial contract that emitted event
     * @param newDefaultTokenManager New default token manager. Zero address if old one was removed
     */
    event DefaultTokenManagerChanged(address indexed contractAddress, address indexed newDefaultTokenManager);

    /**
     * @notice Emitted when default royalty is set
     * @param contractAddress Initial contract that emitted event
     * @param recipientAddress Royalty recipient
     * @param royaltyPercentageBPS Percentage of sale (in basis points) owed to royalty recipient
     */
    event DefaultRoyaltySet(
        address indexed contractAddress,
        address indexed recipientAddress,
        uint16 indexed royaltyPercentageBPS
    );

    /**
     * @notice Emitted when royalties are set for edition / token ids
     * @param contractAddress Initial contract that emitted event
     * @param ids Token / edition ids
     * @param _newRoyalties New royalties for each token / edition
     */
    event GranularRoyaltiesSet(address indexed contractAddress, uint256[] ids, IRoyaltyManager.Royalty[] _newRoyalties);

    /**
     * @notice Emitted when royalty manager is updated
     * @param contractAddress Initial contract that emitted event
     * @param newRoyaltyManager New royalty manager. Zero address if old one was removed
     */
    event RoyaltyManagerChanged(address indexed contractAddress, address indexed newRoyaltyManager);

    /**
     * @notice Emitted when mints are frozen permanently
     * @param contractAddress Initial contract that emitted event
     */
    event MintsFrozen(address indexed contractAddress);

    /**
     * @notice Emitted when contract metadata is set
     * @param contractAddress Initial contract that emitted event
     * @param name New name
     * @param symbol New symbol
     * @param contractURI New contract uri
     */
    event ContractMetadataSet(address indexed contractAddress, string name, string symbol, string contractURI);

    /**************************
      ERC721General events
     **************************/

    /**
     * @notice Emitted when hashed metadata config is set
     * @param contractAddress Initial contract that emitted event
     * @param hashedURIData Hashed uri data
     * @param hashedRotationData Hashed rotation key
     * @param _supply Supply of tokens to mint w/ reveal
     */
    event HashedMetadataConfigSet(
        address indexed contractAddress,
        bytes hashedURIData,
        bytes hashedRotationData,
        uint256 indexed _supply
    );

    /**
     * @notice Emitted when metadata is revealed
     * @param contractAddress Initial contract that emitted event
     * @param key Key used to decode hashed data
     * @param newRotationKey Actual rotation key to be used
     */
    event Revealed(address indexed contractAddress, bytes key, uint256 newRotationKey);

    /**************************
      ERC721GeneralBase events
     **************************/

    /**
     * @notice Emitted when uris are set for tokens
     * @param contractAddress Initial contract that emitted event
     * @param ids IDs of tokens to set uris for
     * @param uris Uris to set on tokens
     */
    event TokenURIsSet(address indexed contractAddress, uint256[] ids, string[] uris);

    /**
     * @notice Emitted when limit supply is set
     * @param contractAddress Initial contract that emitted event
     * @param newLimitSupply Limit supply to set
     */
    event LimitSupplySet(address indexed contractAddress, uint256 indexed newLimitSupply);

    /**************************
      ERC721StorageUri events
     **************************/

    /**
     * @notice Emits when a series collection has its base uri set
     * @param contractAddress Contract with updated base uri
     * @param newBaseUri New base uri
     */
    event BaseUriSet(address indexed contractAddress, string newBaseUri);

    /**************************
      ERC721Editions / ERC721SingleEdition events
     **************************/

    // Not adding EditionCreated, EditionMintedToOneRecipient, EditionMintedToRecipients
    // EditionCreated - handled by MetadataInitialized
    // EditionMintedToOneRecipient / EditionMintedToRecipients - handled via mint module events

    /**************************
      Deployment events
     **************************/

    /**
     * @notice Emitted when Generative Series contract is deployed
     * @param deployer Contract deployer
     * @param contractAddress Address of contract that was deployed
     */
    event GenerativeSeriesDeployed(address indexed deployer, address indexed contractAddress);

    /**
     * @notice Emitted when Series contract is deployed
     * @param deployer Contract deployer
     * @param contractAddress Address of contract that was deployed
     */
    event SeriesDeployed(address indexed deployer, address indexed contractAddress);

    /**
     * @notice Emitted when MultipleEditions contract is deployed
     * @param deployer Contract deployer
     * @param contractAddress Address of contract that was deployed
     */
    event MultipleEditionsDeployed(address indexed deployer, address indexed contractAddress);

    /**
     * @notice Emitted when SingleEdition contract is deployed
     * @param deployer Contract deployer
     * @param contractAddress Address of contract that was deployed
     */
    event SingleEditionDeployed(address indexed deployer, address indexed contractAddress);

    /**************************
      ERC721 events
     **************************/

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to` on contractAddress
     * @param contractAddress NFT contract token resides on
     * @param from Token sender
     * @param to Token receiver
     * @param tokenId Token being sent
     */
    event Transfer(address indexed contractAddress, address indexed from, address to, uint256 indexed tokenId);

    /**
     * @notice Emit MinterRegistrationChanged
     */
    function emitMinterRegistrationChanged(address minter, bool registered) external;

    /**
     * @notice Emit GranularTokenManagersSet
     */
    function emitGranularTokenManagersSet(uint256[] calldata _ids, address[] calldata _tokenManagers) external;

    /**
     * @notice Emit GranularTokenManagersRemoved
     */
    function emitGranularTokenManagersRemoved(uint256[] calldata _ids) external;

    /**
     * @notice Emit DefaultTokenManagerChanged
     */
    function emitDefaultTokenManagerChanged(address newDefaultTokenManager) external;

    /**
     * @notice Emit DefaultRoyaltySet
     */
    function emitDefaultRoyaltySet(address recipientAddress, uint16 royaltyPercentageBPS) external;

    /**
     * @notice Emit GranularRoyaltiesSet
     */
    function emitGranularRoyaltiesSet(uint256[] calldata ids, IRoyaltyManager.Royalty[] calldata _newRoyalties)
        external;

    /**
     * @notice Emit RoyaltyManagerChanged
     */
    function emitRoyaltyManagerChanged(address newRoyaltyManager) external;

    /**
     * @notice Emit MintsFrozen
     */
    function emitMintsFrozen() external;

    /**
     * @notice Emit ContractMetadataSet
     */
    function emitContractMetadataSet(
        string calldata name,
        string calldata symbol,
        string calldata contractURI
    ) external;

    /**
     * @notice Emit HashedMetadataConfigSet
     */
    function emitHashedMetadataConfigSet(
        bytes calldata hashedURIData,
        bytes calldata hashedRotationData,
        uint256 _supply
    ) external;

    /**
     * @notice Emit Revealed
     */
    function emitRevealed(bytes calldata key, uint256 newRotationKey) external;

    /**
     * @notice Emit TokenURIsSet
     */
    function emitTokenURIsSet(uint256[] calldata ids, string[] calldata uris) external;

    /**
     * @notice Emit LimitSupplySet
     */
    function emitLimitSupplySet(uint256 newLimitSupply) external;

    /**
     * @notice Emit BaseUriSet
     */
    function emitBaseUriSet(string calldata newBaseUri) external;

    /**
     * @notice Emit GenerativeSeriesDeployed
     */
    function emitGenerativeSeriesDeployed(address contractAddress) external;

    /**
     * @notice Emit SeriesDeployed
     */
    function emitSeriesDeployed(address contractAddress) external;

    /**
     * @notice Emit MultipleEditionsDeployed
     */
    function emitMultipleEditionsDeployed(address contractAddress) external;

    /**
     * @notice Emit SingleEditionDeployed
     */
    function emitSingleEditionDeployed(address contractAddress) external;

    /**
     * @notice Emit Transfer
     */
    function emitTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title IRoyaltyManager
 * @author [email protected]
 * @notice Enables interfacing with custom royalty managers that define conditions on setting royalties for
 *         NFT contracts
 */
interface IRoyaltyManager {
    /**
     * @notice Struct containing values required to adhere to ERC-2981
     * @param recipientAddress Royalty recipient - can be EOA, royalty splitter contract, etc.
     * @param royaltyPercentageBPS Royalty cut, in basis points
     */
    struct Royalty {
        address recipientAddress;
        uint16 royaltyPercentageBPS;
    }

    /**
     * @notice Defines conditions around being able to swap royalty manager for another one
     * @param newRoyaltyManager New royalty manager being swapped in
     * @param sender msg sender
     */
    function canSwap(address newRoyaltyManager, address sender) external view returns (bool);

    /**
     * @notice Defines conditions around being able to remove current royalty manager
     * @param sender msg sender
     */
    function canRemoveItself(address sender) external view returns (bool);

    /**
     * @notice Defines conditions around being able to set granular royalty (per token or per edition)
     * @param id Edition / token ID whose royalty is being set
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetGranularRoyalty(
        uint256 id,
        Royalty calldata royalty,
        address sender
    ) external view returns (bool);

    /**
     * @notice Defines conditions around being able to set default royalty
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetDefaultRoyalty(Royalty calldata royalty, address sender) external view returns (bool);
}