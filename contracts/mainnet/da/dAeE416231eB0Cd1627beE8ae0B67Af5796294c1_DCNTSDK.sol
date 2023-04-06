// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IDCNTRegistry.sol";
import "./interfaces/IDCNTSeries.sol";
import "./storage/EditionConfig.sol";
import "./storage/MetadataConfig.sol";
import "./storage/TokenGateConfig.sol";
import "./storage/CrescendoConfig.sol";

contract DCNTSDK is Ownable {
  /// ============ Storage ===========
  /// @notice implementation addresses for base contracts
  address public DCNT721AImplementation;
  address public DCNT4907AImplementation;
  address public DCNTSeriesImplementation;
  address public DCNTCrescendoImplementation;
  address public DCNTVaultImplementation;
  address public DCNTStakingImplementation;
  address public ZKEditionImplementation;

  /// @notice address of the metadata renderer
  address public metadataRenderer;

  /// @notice address of the associated registry
  address public contractRegistry;

  /// ============ Events ============

  /// @notice Emitted after successfully deploying a contract
  event DeployDCNT721A(address DCNT721A);
  event DeployDCNT4907A(address DCNT4907A);
  event DeployDCNTSeries(address DCNTSeries);
  event DeployDCNTCrescendo(address DCNTCrescendo);
  event DeployDCNTVault(address DCNTVault);
  event DeployDCNTStaking(address DCNTStaking);
  event DeployZKEdition(address ZKEdition);

  /// ============ Constructor ============

  /// @notice Creates a new DecentSDK instance
  constructor(
    address _DCNT721AImplementation,
    address _DCNT4907AImplementation,
    address _DCNTSeriesImplementation,
    address _DCNTCrescendoImplementation,
    address _DCNTVaultImplementation,
    address _DCNTStakingImplementation,
    address _metadataRenderer,
    address _contractRegistry,
    address _ZKEditionImplementation
  ) {
    DCNT721AImplementation = _DCNT721AImplementation;
    DCNT4907AImplementation = _DCNT4907AImplementation;
    DCNTSeriesImplementation = _DCNTSeriesImplementation;
    DCNTCrescendoImplementation = _DCNTCrescendoImplementation;
    DCNTVaultImplementation = _DCNTVaultImplementation;
    DCNTStakingImplementation = _DCNTStakingImplementation;
    metadataRenderer = _metadataRenderer;
    contractRegistry = _contractRegistry;
    ZKEditionImplementation = _ZKEditionImplementation;
  }

  /// ============ Functions ============

  /// @notice deploy and initialize an erc721a clone
  function deployDCNT721A(
    EditionConfig calldata _editionConfig,
    MetadataConfig calldata _metadataConfig,
    TokenGateConfig calldata _tokenGateConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNT721AImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,bool,bool,uint32,uint32,uint32,uint32,uint32,uint32,uint16,uint96,address,bytes32),"
          "(string,string,bytes,address),"
          "(address,uint88,uint8),"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        _tokenGateConfig,
        metadataRenderer
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNT721A");
    emit DeployDCNT721A(clone);
  }

  /// @notice deploy and initialize a ZKEdition clone
  function deployZKEdition(
    EditionConfig calldata _editionConfig,
    MetadataConfig calldata _metadataConfig,
    TokenGateConfig calldata _tokenGateConfig,
    address zkVerifier
  ) external returns (address clone) {
    clone = Clones.clone(ZKEditionImplementation); //zkedition implementation
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,bool,bool,uint32,uint32,uint32,uint32,uint32,uint32,uint16,uint96,address,bytes32),"
          "(string,string,bytes,address),"
          "(address,uint88,uint8),"
          "address,"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        _tokenGateConfig,
        metadataRenderer,
        zkVerifier
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "ZKEdition");
    emit DeployZKEdition(clone);
  }

  /// @notice deploy and initialize an erc4907a clone
  function deployDCNT4907A(
    EditionConfig calldata _editionConfig,
    MetadataConfig calldata _metadataConfig,
    TokenGateConfig calldata _tokenGateConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNT4907AImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,bool,bool,uint32,uint32,uint32,uint32,uint32,uint32,uint16,uint96,address,bytes32),"
          "(string,string,bytes,address),"
          "(address,uint88,uint8),"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        _tokenGateConfig,
        metadataRenderer
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNT4907A");
    emit DeployDCNT4907A(clone);
  }

  // deploy and initialize an erc1155 clone
  function deployDCNTSeries(
    IDCNTSeries.SeriesConfig calldata _config,
    IDCNTSeries.Drop calldata _defaultDrop,
    IDCNTSeries.DropMap calldata _dropOverrides
  ) external returns (address clone) {
    clone = Clones.clone(DCNTSeriesImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,string,string,uint128,uint128,uint16,address,address,address,bool,bool),"
          "(uint32,uint32,uint32,uint32,uint32,uint32,uint96,bytes32,(address,uint88,uint8)),"
          "("
            "uint256[],"
            "uint256[],"
            "uint256[],"
            "(uint32,uint32,uint32,uint32,uint32,uint32,uint96,bytes32,(address,uint88,uint8))[]"
          ")"
        ")",
        msg.sender,
        _config,
        _defaultDrop,
        _dropOverrides
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(
      msg.sender,
      clone,
      "DCNTSeries"
    );
    emit DeployDCNTSeries(clone);
  }

  // deploy and initialize a Crescendo clone
  function deployDCNTCrescendo(
    CrescendoConfig calldata _config,
    MetadataConfig calldata _metadataConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNTCrescendoImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),"
          "(string,string,bytes,address),"
          "address"
        ")",
        msg.sender,
        _config,
        _metadataConfig,
        metadataRenderer
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(
      msg.sender,
      clone,
      "DCNTCrescendo"
    );
    emit DeployDCNTCrescendo(clone);
  }

  // deploy and initialize a vault wrapper clone
  function deployDCNTVault(
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) external returns (address clone) {
    clone = Clones.clone(DCNTVaultImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
        msg.sender,
        _vaultDistributionTokenAddress,
        _nftVaultKeyAddress,
        _nftTotalSupply,
        _unlockDate
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNTVault");
    emit DeployDCNTVault(clone);
  }

  // deploy and initialize a vault wrapper clone
  function deployDCNTStaking(
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) external returns (address clone) {
    clone = Clones.clone(DCNTStakingImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
        msg.sender,
        _nft,
        _token,
        _vaultDuration,
        _totalSupply
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNTStaking");
    emit DeployDCNTStaking(clone);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'solmate/src/tokens/ERC1155.sol';

abstract contract ERC1155Hooks is ERC1155 {
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) public virtual override {
    _beforeTokenTransfers(from, to, _asSingletonArray(id), _asSingletonArray(amount));
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual override {
    _beforeTokenTransfers(from, to, ids, amounts);
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    _beforeTokenTransfers(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));
    super._mint(to, id, amount, data);
  }

  function _batchMint(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    _beforeTokenTransfers(address(0), to, ids, amounts);
    super._batchMint(to, ids, amounts, data);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual override {
    _beforeTokenTransfers(msg.sender, address(0), _asSingletonArray(id), _asSingletonArray(amount));
    super._burn(from, id, amount);
  }

  function _batchBurn(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual override {
    _beforeTokenTransfers(msg.sender, address(0), ids, amounts);
    super._batchBurn(from, ids, amounts);
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;
    return array;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDCNTRegistry {
  function register(
    address _deployer,
    address _deployment,
    string calldata _key
  ) external;

  function remove(address _deployer, address _deployment) external;

  function query(address _deployer) external returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '../extensions/ERC1155Hooks.sol';
import '../storage/TokenGateConfig.sol';

/**
 * @title IDCNTSeries
 * @author Zev Nevo. Will Kantaros.
 * @dev An implementation of the ERC1155 multi-token standard.
 */
interface IDCNTSeries {
  /*
   * @dev A parameter object used to set the initial configuration of a token series.
   */
  struct SeriesConfig {
    string name;
    string symbol;
    string contractURI;
    string metadataURI;
    uint128 startTokenId;
    uint128 endTokenId;
    uint16 royaltyBPS;
    address feeManager;
    address payoutAddress;
    address currencyOracle;
    bool isSoulbound;
    bool hasAdjustableCaps;
  }

  /*
   * @dev The configuration settings for individual tokens within the series
   */
  struct Drop {
    uint32 maxTokens;                  // Slot 1: XXXX---------------------------- 4  bytes (max: 4,294,967,295)
    uint32 maxTokensPerOwner;          // Slot 1: ----XXXX------------------------ 4  bytes (max: 4,294,967,295)
    uint32 presaleStart;               // Slot 1: --------XXXX-------------------- 4  bytes (max: Feburary 7th, 2106)
    uint32 presaleEnd;                 // Slot 1: ------------XXXX---------------- 4  bytes (max: Feburary 7th, 2106)
    uint32 saleStart;                  // Slot 1: ----------------XXXX------------ 4  bytes (max: Feburary 7th, 2106)
    uint32 saleEnd;                    // Slot 1: --------------------XXXX-------- 4  bytes (max: Feburary 7th, 2106)
    uint96 tokenPrice;                 // Slot 2: XXXXXXXXXXXX-------------------- 12  bytes (max: 79,228,162,514 ETH)
    bytes32 presaleMerkleRoot;         // Slot 3: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 32 bytes
    TokenGateConfig tokenGate;         // Slot 4: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 32 bytes
  }

  /**
   * @dev A parameter object mapping token IDs, drop IDs, and drops.
   */
  struct DropMap {
    uint256[] tokenIds;
    uint256[] tokenIdDropIds;
    uint256[] dropIds;
    Drop[] drops;
  }

  /*
   * @dev Only admins can perform this action.
   */
  error OnlyAdmin();

  /*
   * @dev The provided arrays have unequal lengths.
   */
  error ArrayLengthMismatch();

  /*
   * @dev The requested token does not exist.
   */
  error NonexistentToken();

  /*
   * @dev The provided token range is invalid.
   */
  error InvalidTokenRange();

  /*
   * @dev The token supply caps are locked and cannot be adjusted.
   */
  error CapsAreLocked();

  /*
   * @dev The token supply cap cannot be decreased.
   */
  error CannotDecreaseCap();

  /*
   * @dev Insufficient minimum balance for the token gate.
   */
  error TokenGateDenied();

  /*
   * @dev Sales for this drop are not currently active.
   */
  error SaleNotActive();

  /*
   * @dev The provided funds are insufficient to complete this transaction.
   */
  error InsufficientFunds();

  /*
   * @dev The requested mint exceeds the maximum supply for this drop.
   */
  error MintExceedsMaxSupply();

  /*
   * @dev The requested mint exceeds the maximum tokens per owner for this drop.
   */
  error MintExceedsMaxTokensPerOwner();

  /*
   * @dev The requested airdrop exceeds the maximum supply for this drop.
   */
  error AirdropExceedsMaxSupply();

  /*
   * @dev The requested burn exceeds the number of owned tokens.
   */
  error BurnExceedsOwnedTokens();

  /*
   * @dev The presale is not currently active.
   */
  error PresaleNotActive();

  /*
   * @dev Verification for the presale failed.
   */
  error PresaleVerificationFailed();

  /*
   * @dev Soulbound tokens cannot be transferred.
   */
  error CannotTransferSoulbound();

  /*
   * @dev Basis points may not exceed 100_00 (100 percent)
   */
  error InvalidBPS();

  /*
   * @dev Splits are currently active and withdrawals are disabled.
   */
  error SplitsAreActive();

  /*
   * @dev Transfer of fees failed.
   */
  error FeeTransferFailed();

  /*
   * @dev Refund of excess funds failed.
   */
  error RefundFailed();

  /*
   * @dev Withdrawal of funds failed.
   */
  error WithdrawFailed();

  /**
   * @dev Initializes the contract with the specified parameters.
   * param _owner The owner of the contract.
   * param _config The configuration for the contract.
   * param _drops The drop configurations for the initial tokens.
   */
  function initialize(
    address _owner,
    SeriesConfig calldata _config,
    Drop calldata _defaultDrop,
    DropMap calldata _dropOverrides
  ) external;

  /**
   * @dev Returns the name of the contract.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the contract.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the URI for a given token ID.
   * A single URI is returned for all token types as defined in EIP-1155's token type ID substitution mechanism.
   * Clients should replace `{id}` with the actual token type ID when calling the function.
   * @dev unused @param tokenId ID of the token to retrieve the URI for.
   */
  function uri(uint256) external view returns (string memory);

  /**
   * @dev Set the URI for all token IDs.
   * @param uri_ The URI for token all token IDs.
   */
  function setURI(string memory uri_) external;

  /**
   * @dev Returns the URI of the contract metadata.
   */
  function contractURI() external view returns (string memory);

  /**
   * @dev Sets the URI of the contract metadata.
   * @param contractURI_ The URI of the contract metadata.
   */
  function setContractURI(string memory contractURI_) external;


  /**
   * @dev Returns the range of token IDs that are valid for this contract.
   * @return startTokenId The starting token ID for this contract.
   * @return endTokenId The ending token ID for this contract.
   */
  function tokenRange() external view returns (uint128 startTokenId, uint128 endTokenId);

  /**
   * @dev Returns the drop configuration for the specified token ID.
   * @param tokenId The ID of the token to retrieve the drop configuration for.
   * @return drop The drop configuration mapped to the specified token ID.
   */
  function tokenDrop(uint128 tokenId) external view returns (Drop memory);

  /**
   * @dev Creates new tokens and updates drop configurations for specified token IDs.
   * @param newTokens Optional number of new token IDs to add to the existing token range.
   * @param dropMap Optional parameter object mapping token IDs, drop IDs, and drops.
   */
  function setTokenDrops(uint128 newTokens, DropMap calldata dropMap) external;

  /**
   * @dev Gets the current price for the specified token. If a currency oracle is set,
   * the price is calculated in native currency using the oracle exchange rate.
   * @param tokenId The ID of the token to get the price for.
   * @return The current price of the specified token.
   */
  function tokenPrice(uint256 tokenId) external view returns (uint256);

  /**
   * @dev Gets the current minting fee for the specified token.
   * @param tokenId The ID of the token to get the minting fee for.
   * @param quantity The quantity of tokens used to calculate the minting fee.
   * @return The current fee for minting the specified token.
   */
  function mintFee(uint256 tokenId, uint256 quantity) external view returns (uint256);

  /**
   * @dev Mints a specified number of tokens to a specified address.
   * @param tokenId The ID of the token to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantity The quantity of tokens to mint.
   */
  function mint(uint256 tokenId, address to, uint256 quantity) external payable;

  /**
   * @dev Mints a batch of tokens to a specified address.
   * @param tokenIds The IDs of the tokens to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantities The quantities to mint of each token.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  ) external payable;

  /**
   * @dev Burns a specified quantity of tokens from the caller's account.
   * @param tokenId The ID of the token to burn.
   * @param quantity The quantity of tokens to burn.
   */
  function burn(uint256 tokenId, uint256 quantity) external;

  /**
   * @dev Mints a specified token to multiple recipients as part of an airdrop.
   * @param tokenId The ID of the token to mint.
   * @param recipients The list of addresses to receive the minted tokens.
   */
  function mintAirdrop(uint256 tokenId, address[] calldata recipients) external;

  /**
   * @dev Mints a specified number of tokens to the presale buyer address.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   * @param maxQuantity The maximum quantity of tokens that can be minted.
   * @param pricePerToken The price per token in wei.
   * @param merkleProof The Merkle proof verifying that the presale buyer is eligible to mint tokens.
   */
  function mintPresale(
    uint256 tokenId,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  ) external payable;

  /**
   * @dev Pauses public minting.
   */
  function pause() external;

  /**
   * @dev Unpauses public minting.
   */
  function unpause() external;

  /**
   * @dev Sets the payout address to the specified address.
   * Use 0x0 to default to the contract owner.
   * @param _payoutAddress The address to set as the payout address.
   */
  function setPayoutAddress(address _payoutAddress) external;

  /**
   * @dev Withdraws the balance of the contract to the payout address or the contract owner.
  */
  function withdraw() external;

  /**
   * @dev Sets the royalty fee (ERC-2981: NFT Royalty Standard).
   * @param _royaltyBPS The royalty fee in basis points. (1/100th of a percent)
   */
  function setRoyaltyBPS(uint16 _royaltyBPS) external;

  /**
   * @dev Returns the royalty recipient and amount for a given sale price.
   * @param tokenId The ID of the token being sold.
   * @param salePrice The sale price of the token.
   * @return receiver The address of the royalty recipient.
   * @return royaltyAmount The amount to be paid to the royalty recipient.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);

  /**
   * @dev Returns true if the contract supports the given interface (ERC2981 or ERC1155),
   * as specified by interfaceId, false otherwise.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceId, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);

  /**
   * @dev Updates the operator filter registry with the specified subscription.
   * @param enable If true, enables the operator filter, if false, disables it.
   * @param operatorFilter The address of the operator filter subscription.
   */
  function updateOperatorFilter(bool enable, address operatorFilter) external;

  /**
   * @dev Sets or revokes approval for a third party ("operator") to manage all of the caller's tokens.
   * @param operator The address of the operator to grant or revoke approval.
   * @param approved True to grant approval, false to revoke it.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct CrescendoConfig {
  string name;
  string symbol;
  uint256 initialPrice;
  uint256 step1;
  uint256 step2;
  uint256 hitch;
  uint256 takeRateBPS;
  uint256 unlockDate;
  uint256 saleStart;
  uint256 royaltyBPS;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EditionConfig {
  string name;
  string symbol;
  bool hasAdjustableCap;
  bool isSoulbound;
  uint32 maxTokens;
  uint32 maxTokenPurchase;
  uint32 presaleStart;
  uint32 presaleEnd;
  uint32 saleStart;
  uint32 saleEnd;
  uint16 royaltyBPS;
  uint96 tokenPrice;
  address payoutAddress;
  bytes32 presaleMerkleRoot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct MetadataConfig {
  string contractURI;
  string metadataURI;
  bytes metadataRendererInit;
  address parentIP;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum SaleType {
  ALL,
  PRESALE,
  PRIMARY
}

struct TokenGateConfig {
  address tokenAddress; 
  uint88 minBalance;
  SaleType saleType;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}