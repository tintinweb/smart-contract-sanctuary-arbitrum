// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "../interface/InitializableInterface.sol";

/**
 * @title Initializable
 * @author https://github.com/holographxyz
 * @notice Use init instead of constructor
 * @dev This allows for use of init function to make one time initializations without the need for a constructor
 */
abstract contract Initializable is InitializableInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.initialized')) - 1)
   */
  bytes32 constant _initializedSlot = 0x4e5f991bca30eca2d4643aaefa807e88f96a4a97398933d572a3c0d973004a01;

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external virtual returns (bytes4);

  function _isInitialized() internal view returns (bool initialized) {
    assembly {
      initialized := sload(_initializedSlot)
    }
  }

  function _setInitialized() internal {
    assembly {
      sstore(_initializedSlot, 0x0000000000000000000000000000000000000000000000000000000000000001)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IMetadataRenderer} from "./IMetadataRenderer.sol";

import {AddressMintDetails} from "../struct/AddressMintDetails.sol";
import {SaleDetails} from "../struct/SaleDetails.sol";

/// @notice Interface for HOLOGRAPH Drops contract
interface IHolographDropERC721 {
  // Access errors

  /// @notice Only admin can access this function
  error Access_OnlyAdmin();
  /// @notice Missing the given role or admin access
  error Access_MissingRoleOrAdmin(bytes32 role);
  /// @notice Withdraw is not allowed by this user
  error Access_WithdrawNotAllowed();
  /// @notice Cannot withdraw funds due to ETH send failure.
  error Withdraw_FundsSendFailure();
  /// @notice Mint fee send failure
  error MintFee_FundsSendFailure();

  /// @notice Call to external metadata renderer failed.
  error ExternalMetadataRenderer_CallFailed();

  /// @notice Thrown when the operator for the contract is not allowed
  /// @dev Used when strict enforcement of marketplaces for creator royalties is desired.
  error OperatorNotAllowed(address operator);

  /// @notice Thrown when there is no active market filter DAO address supported for the current chain
  /// @dev Used for enabling and disabling filter for the given chain.
  error MarketFilterDAOAddressNotSupportedForChain();

  /// @notice Used when the operator filter registry external call fails
  /// @dev Used for bubbling error up to clients.
  error RemoteOperatorFilterRegistryCallFailed();

  // Sale/Purchase errors
  /// @notice Sale is inactive
  error Sale_Inactive();
  /// @notice Presale is inactive
  error Presale_Inactive();
  /// @notice Presale merkle root is invalid
  error Presale_MerkleNotApproved();
  /// @notice Wrong price for purchase
  error Purchase_WrongPrice(uint256 correctPrice);
  /// @notice NFT sold out
  error Mint_SoldOut();
  /// @notice Too many purchase for address
  error Purchase_TooManyForAddress();
  /// @notice Too many presale for address
  error Presale_TooManyForAddress();

  // Admin errors
  /// @notice Royalty percentage too high
  error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
  /// @notice Invalid admin upgrade address
  error Admin_InvalidUpgradeAddress(address proposedAddress);
  /// @notice Unable to finalize an edition not marked as open (size set to uint64_max_value)
  error Admin_UnableToFinalizeNotOpenEdition();

  /// @notice Event emitted for mint fee payout
  /// @param mintFeeAmount amount of the mint fee
  /// @param mintFeeRecipient recipient of the mint fee
  /// @param success if the payout succeeded
  event MintFeePayout(uint256 mintFeeAmount, address mintFeeRecipient, bool success);

  /// @notice Event emitted for each sale
  /// @param to address sale was made to
  /// @param quantity quantity of the minted nfts
  /// @param pricePerToken price for each token
  /// @param firstPurchasedTokenId first purchased token ID (to get range add to quantity for max)
  event Sale(
    address indexed to,
    uint256 indexed quantity,
    uint256 indexed pricePerToken,
    uint256 firstPurchasedTokenId
  );

  /// @notice Sales configuration has been changed
  /// @dev To access new sales configuration, use getter function.
  /// @param changedBy Changed by user
  event SalesConfigChanged(address indexed changedBy);

  /// @notice Event emitted when the funds recipient is changed
  /// @param newAddress new address for the funds recipient
  /// @param changedBy address that the recipient is changed by
  event FundsRecipientChanged(address indexed newAddress, address indexed changedBy);

  /// @notice Event emitted when the funds are withdrawn from the minting contract
  /// @param withdrawnBy address that issued the withdraw
  /// @param withdrawnTo address that the funds were withdrawn to
  /// @param amount amount that was withdrawn
  /// @param feeRecipient user getting withdraw fee (if any)
  /// @param feeAmount amount of the fee getting sent (if any)
  event FundsWithdrawn(
    address indexed withdrawnBy,
    address indexed withdrawnTo,
    uint256 amount,
    address feeRecipient,
    uint256 feeAmount
  );

  /// @notice Event emitted when an open mint is finalized and further minting is closed forever on the contract.
  /// @param sender address sending close mint
  /// @param numberOfMints number of mints the contract is finalized at
  event OpenMintFinalized(address indexed sender, uint256 numberOfMints);

  /// @notice Event emitted when metadata renderer is updated.
  /// @param sender address of the updater
  /// @param renderer new metadata renderer address
  event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

  /// @notice Admin function to update the sales configuration settings
  /// @param publicSalePrice public sale price in ether
  /// @param maxSalePurchasePerAddress Max # of purchases (public) per address allowed
  /// @param publicSaleStart unix timestamp when the public sale starts
  /// @param publicSaleEnd unix timestamp when the public sale ends (set to 0 to disable)
  /// @param presaleStart unix timestamp when the presale starts
  /// @param presaleEnd unix timestamp when the presale ends
  /// @param presaleMerkleRoot merkle root for the presale information
  function setSaleConfiguration(
    uint104 publicSalePrice,
    uint32 maxSalePurchasePerAddress,
    uint64 publicSaleStart,
    uint64 publicSaleEnd,
    uint64 presaleStart,
    uint64 presaleEnd,
    bytes32 presaleMerkleRoot
  ) external;

  /// @notice External purchase function (payable in eth)
  /// @param quantity to purchase
  /// @return first minted token ID
  function purchase(uint256 quantity) external payable returns (uint256);

  /// @notice External purchase presale function (takes a merkle proof and matches to root) (payable in eth)
  /// @param quantity to purchase
  /// @param maxQuantity can purchase (verified by merkle root)
  /// @param pricePerToken price per token allowed (verified by merkle root)
  /// @param merkleProof input for merkle proof leaf verified by merkle root
  /// @return first minted token ID
  function purchasePresale(
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] memory merkleProof
  ) external payable returns (uint256);

  /// @notice Function to return the global sales details for the given drop
  function saleDetails() external view returns (SaleDetails memory);

  /// @notice Function to return the specific sales details for a given address
  /// @param minter address for minter to return mint information for
  function mintedPerAddress(address minter) external view returns (AddressMintDetails memory);

  /// @notice This is the opensea/public owner setting that can be set by the contract admin
  function owner() external view returns (address);

  /// @notice Update the metadata renderer
  /// @param newRenderer new address for renderer
  /// @param setupRenderer data to call to bootstrap data for the new renderer (optional)
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external;

  /// @notice This is an admin mint function to mint a quantity to a specific address
  /// @param to address to mint to
  /// @param quantity quantity to mint
  /// @return the id of the first minted NFT
  function adminMint(address to, uint256 quantity) external returns (uint256);

  /// @notice This is an admin mint function to mint a single nft each to a list of addresses
  /// @param to list of addresses to mint an NFT each to
  /// @return the id of the first minted NFT
  function adminMintAirdrop(address[] memory to) external returns (uint256);

  /// @dev Getter for admin role associated with the contract to handle metadata
  /// @return boolean if address is admin
  function isAdmin(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMetadataRenderer {
  function tokenURI(uint256) external view returns (string memory);

  function contractURI() external view returns (string memory);

  function initializeWithData(bytes memory initData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../abstract/Initializable.sol";

import {IMetadataRenderer} from "../interface/IMetadataRenderer.sol";
import {IHolographDropERC721} from "../interface/IHolographDropERC721.sol";
import {ERC721Metadata} from "../../interface/ERC721Metadata.sol";
import {NFTMetadataRenderer} from "../utils/NFTMetadataRenderer.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

import {Configuration} from "../struct/Configuration.sol";

interface DropConfigGetter {
  function config() external view returns (Configuration memory config);
}

/// @notice EditionsMetadataRenderer for editions support
contract EditionsMetadataRenderer is Initializable, IMetadataRenderer, MetadataRenderAdminCheck {
  /// @notice Storage for token edition information
  struct TokenEditionInfo {
    string description;
    string imageURI;
    string animationURI;
  }

  /// @notice Event for updated Media URIs
  event MediaURIsUpdated(address indexed target, address sender, string imageURI, string animationURI);

  /// @notice Event for a new edition initialized
  /// @dev admin function indexer feedback
  event EditionInitialized(address indexed target, string description, string imageURI, string animationURI);

  /// @notice Description updated for this edition
  /// @dev admin function indexer feedback
  event DescriptionUpdated(address indexed target, address sender, string newDescription);

  /// @notice Token information mapping storage
  mapping(address => TokenEditionInfo) public tokenInfos;

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @dev A blank init function is required to be able to call genesisDeriveFutureAddress to get the deterministic address
   * @dev Since no data is required to be intialized the selector is just returned and _setInitialized() does not need to be called
   */
  function init(bytes memory /* initPayload */) external pure override returns (bytes4) {
    return InitializableInterface.init.selector;
  }

  /// @notice Update media URIs
  /// @param target target for contract to update metadata for
  /// @param imageURI new image uri address
  /// @param animationURI new animation uri address
  function updateMediaURIs(
    address target,
    string memory imageURI,
    string memory animationURI
  ) external requireSenderAdmin(target) {
    tokenInfos[target].imageURI = imageURI;
    tokenInfos[target].animationURI = animationURI;
    emit MediaURIsUpdated({target: target, sender: msg.sender, imageURI: imageURI, animationURI: animationURI});
  }

  /// @notice Admin function to update description
  /// @param target target description
  /// @param newDescription new description
  function updateDescription(address target, string memory newDescription) external requireSenderAdmin(target) {
    tokenInfos[target].description = newDescription;

    emit DescriptionUpdated({target: target, sender: msg.sender, newDescription: newDescription});
  }

  /// @notice Default initializer for edition data from a specific contract
  /// @param data data to init with
  function initializeWithData(bytes memory data) external {
    // data format: description, imageURI, animationURI
    (string memory description, string memory imageURI, string memory animationURI) = abi.decode(
      data,
      (string, string, string)
    );

    tokenInfos[msg.sender] = TokenEditionInfo({
      description: description,
      imageURI: imageURI,
      animationURI: animationURI
    });
    emit EditionInitialized({
      target: msg.sender,
      description: description,
      imageURI: imageURI,
      animationURI: animationURI
    });
  }

  /// @notice Contract URI information getter
  /// @return contract uri (if set)
  function contractURI() external view override returns (string memory) {
    address target = msg.sender;
    TokenEditionInfo storage editionInfo = tokenInfos[target];
    Configuration memory config = DropConfigGetter(target).config();

    return
      NFTMetadataRenderer.encodeContractURIJSON({
        name: ERC721Metadata(target).name(),
        description: editionInfo.description,
        imageURI: editionInfo.imageURI,
        animationURI: editionInfo.animationURI,
        royaltyBPS: uint256(config.royaltyBPS),
        royaltyRecipient: config.fundsRecipient
      });
  }

  /// @notice Token URI information getter
  /// @param tokenId to get uri for
  /// @return contract uri (if set)
  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    address target = msg.sender;

    TokenEditionInfo memory info = tokenInfos[target];
    IHolographDropERC721 media = IHolographDropERC721(target);

    uint256 maxSupply = media.saleDetails().maxSupply;

    // For open editions, set max supply to 0 for renderer to remove the edition max number
    // This will be added back on once the open edition is "finalized"
    if (maxSupply == type(uint64).max) {
      maxSupply = 0;
    }

    return
      NFTMetadataRenderer.createMetadataEdition({
        name: ERC721Metadata(target).name(),
        description: info.description,
        imageURI: info.imageURI,
        animationURI: info.animationURI,
        tokenOfEdition: tokenId,
        editionSize: maxSupply
      });
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IHolographDropERC721} from "../interface/IHolographDropERC721.sol";

contract MetadataRenderAdminCheck {
  error Access_OnlyAdmin();

  /// @notice Modifier to require the sender to be an admin
  /// @param target address that the user wants to modify
  modifier requireSenderAdmin(address target) {
    if (target != msg.sender && !IHolographDropERC721(target).isAdmin(msg.sender)) {
      revert Access_OnlyAdmin();
    }

    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @notice Return type of specific mint counts and details per address
struct AddressMintDetails {
  /// Number of total mints from the given address
  uint256 totalMints;
  /// Number of presale mints from the given address
  uint256 presaleMints;
  /// Number of public mints from the given address
  uint256 publicMints;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IMetadataRenderer} from "../interface/IMetadataRenderer.sol";

/// @notice General configuration for NFT Minting and bookkeeping
struct Configuration {
  /// @dev Metadata renderer (uint160)
  IMetadataRenderer metadataRenderer;
  /// @dev Total size of edition that can be minted (uint160+64 = 224)
  uint64 editionSize;
  /// @dev Royalty amount in bps (uint224+16 = 240)
  uint16 royaltyBPS;
  /// @dev Funds recipient for sale (new slot, uint160)
  address payable fundsRecipient;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @notice Return value for sales details to use with front-ends
struct SaleDetails {
  // Synthesized status variables for sale and presale
  bool publicSaleActive;
  bool presaleActive;
  // Price for public sale
  uint256 publicSalePrice;
  // Timed sale actions for public sale
  uint64 publicSaleStart;
  uint64 publicSaleEnd;
  // Timed sale actions for presale
  uint64 presaleStart;
  uint64 presaleEnd;
  // Merkle root (includes address, quantity, and price data for each entry)
  bytes32 presaleMerkleRoot;
  // Limit public sale to a specific number of mints per wallet
  uint256 maxSalePurchasePerAddress;
  // Information about the rest of the supply
  // Total that have been minted
  uint256 totalMinted;
  // The total supply available
  uint256 maxSupply;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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
        return prod0 / denominator;
      }

      // Make sure the result is less than 2^256. Also prevents denominator == 0.
      require(denominator > prod1);

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
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = log256(value);
      return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
    }
  }
}

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
}

library Base64 {
  /**
   * @dev Base64 Encoding/Decoding Table
   */
  string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /**
   * @dev Converts a `bytes` to its Bytes64 `string` representation.
   */
  function encode(bytes memory data) internal pure returns (string memory) {
    /**
     * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
     * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
     */
    if (data.length == 0) return "";

    // Loads the table into memory
    string memory table = _TABLE;

    // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
    // and split into 4 numbers of 6 bits.
    // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
    // - `data.length + 2`  -> Round up
    // - `/ 3`              -> Number of 3-bytes chunks
    // - `4 *`              -> 4 characters for each chunk
    string memory result = new string(4 * ((data.length + 2) / 3));

    /// @solidity memory-safe-assembly
    assembly {
      // Prepare the lookup table (skip the first "length" byte)
      let tablePtr := add(table, 1)

      // Prepare result pointer, jump over length
      let resultPtr := add(result, 32)

      // Run over the input, 3 bytes at a time
      for {
        let dataPtr := data
        let endPtr := add(data, mload(data))
      } lt(dataPtr, endPtr) {

      } {
        // Advance 3 bytes
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)

        // To write each character, shift the 3 bytes (18 bits) chunk
        // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
        // and apply logical AND with 0x3F which is the number of
        // the previous character in the ASCII table prior to the Base64 Table
        // The result is then added to the table to get the character to write,
        // and finally write it in the result pointer but with a left shift
        // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

        mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        resultPtr := add(resultPtr, 1) // Advance

        mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        resultPtr := add(resultPtr, 1) // Advance

        mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        resultPtr := add(resultPtr, 1) // Advance

        mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
        resultPtr := add(resultPtr, 1) // Advance
      }

      // When data `bytes` is not exactly 3 bytes long
      // it is padded with `=` characters at the end
      switch mod(mload(data), 3)
      case 1 {
        mstore8(sub(resultPtr, 1), 0x3d)
        mstore8(sub(resultPtr, 2), 0x3d)
      }
      case 2 {
        mstore8(sub(resultPtr, 1), 0x3d)
      }
    }

    return result;
  }
}

/// NFT metadata library for rendering metadata associated with editions
library NFTMetadataRenderer {
  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name Name of NFT in metadata
  /// @param description Description of NFT in metadata
  /// @param imageURI URI of image to render for edition
  /// @param animationURI URI of animation to render for edition
  /// @param tokenOfEdition Token ID for specific token
  /// @param editionSize Size of entire edition to show
  function createMetadataEdition(
    string memory name,
    string memory description,
    string memory imageURI,
    string memory animationURI,
    uint256 tokenOfEdition,
    uint256 editionSize
  ) internal pure returns (string memory) {
    string memory _tokenMediaData = tokenMediaData(imageURI, animationURI);
    bytes memory json = createMetadataJSON(name, description, _tokenMediaData, tokenOfEdition, editionSize);
    return encodeMetadataJSON(json);
  }

  function encodeContractURIJSON(
    string memory name,
    string memory description,
    string memory imageURI,
    string memory animationURI,
    uint256 royaltyBPS,
    address royaltyRecipient
  ) internal pure returns (string memory) {
    bytes memory imageSpace = bytes("");
    if (bytes(imageURI).length > 0) {
      imageSpace = abi.encodePacked('", "image": "', imageURI);
    }
    bytes memory animationSpace = bytes("");
    if (bytes(animationURI).length > 0) {
      animationSpace = abi.encodePacked('", "animation_url": "', animationURI);
    }

    return
      string(
        encodeMetadataJSON(
          abi.encodePacked(
            '{"name": "',
            name,
            '", "description": "',
            description,
            // this is for opensea since they don't respect ERC2981 right now
            '", "seller_fee_basis_points": ',
            Strings.toString(royaltyBPS),
            ', "fee_recipient": "',
            Strings.toHexString(uint256(uint160(royaltyRecipient)), 20),
            imageSpace,
            animationSpace,
            '"}'
          )
        )
      );
  }

  /// Function to create the metadata json string for the nft edition
  /// @param name Name of NFT in metadata
  /// @param description Description of NFT in metadata
  /// @param mediaData Data for media to include in json object
  /// @param tokenOfEdition Token ID for specific token
  /// @param editionSize Size of entire edition to show
  function createMetadataJSON(
    string memory name,
    string memory description,
    string memory mediaData,
    uint256 tokenOfEdition,
    uint256 editionSize
  ) internal pure returns (bytes memory) {
    bytes memory editionSizeText;
    if (editionSize > 0) {
      editionSizeText = abi.encodePacked("/", Strings.toString(editionSize));
    }
    return
      abi.encodePacked(
        '{"name": "',
        name,
        " ",
        Strings.toString(tokenOfEdition),
        editionSizeText,
        '", "',
        'description": "',
        description,
        '", "',
        mediaData,
        'properties": {"number": ',
        Strings.toString(tokenOfEdition),
        ', "name": "',
        name,
        '"}}'
      );
  }

  /// Encodes the argument json bytes into base64-data uri format
  /// @param json Raw json to base64 and turn into a data-uri
  function encodeMetadataJSON(bytes memory json) internal pure returns (string memory) {
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
  }

  /// Generates edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param imageUrl URL of image to render for edition
  /// @param animationUrl URL of animation to render for edition
  function tokenMediaData(string memory imageUrl, string memory animationUrl) internal pure returns (string memory) {
    bool hasImage = bytes(imageUrl).length > 0;
    bool hasAnimation = bytes(animationUrl).length > 0;
    if (hasImage && hasAnimation) {
      return string(abi.encodePacked('image": "', imageUrl, '", "animation_url": "', animationUrl, '", "'));
    }
    if (hasImage) {
      return string(abi.encodePacked('image": "', imageUrl, '", "'));
    }
    if (hasAnimation) {
      return string(abi.encodePacked('animation_url": "', animationUrl, '", "'));
    }

    return "";
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface ERC721Metadata {
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

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

/**
 * @title Initializable
 * @author https://github.com/holographxyz
 * @notice Use init instead of constructor
 * @dev This allows for use of init function to make one time initializations without the need of a constructor
 */
interface InitializableInterface {
  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external returns (bytes4);
}