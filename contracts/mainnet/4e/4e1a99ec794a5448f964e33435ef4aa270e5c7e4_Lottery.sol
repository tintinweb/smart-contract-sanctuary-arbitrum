// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {NFT, Auth, Authority} from "./token/NFT.sol";
import {Issuer} from "./Issuer.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract Lottery is Auth, VRFV2WrapperConsumerBase {
    Issuer public immutable issuer;

    struct Raffle {
        NFT ticket;
        NFT prize;
        uint32 endTime;
        uint32 offset;
        uint256 requestId;
        bool drawn;
    }

    uint256 public raffleCount;

    mapping(uint256 raffleId => Raffle raffle) public raffles;
    mapping(uint256 requestId => uint256 raffleId) public raffleRequests;

    event RaffleCreated(uint256 indexed raffleId, address indexed ticket, address indexed prize, uint32 end);
    event RaffleStarted(uint256 indexed raffleId, uint256 requestId);
    event RaffleDrawn(uint256 indexed raffleId, uint256 offset);

    constructor(address _owner, Authority _authority, Issuer _issuer, address _link, address _vrfV2Wrapper)
        Auth(_owner, _authority)
        VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper)
    {
        issuer = _issuer;
    }

    function startRaffleFor(NFT ticket, NFT prize, uint32 endTime) external requiresAuth returns (uint256 raffleId) {
        raffleId = raffleCount++;
        raffles[raffleId] = Raffle(ticket, prize, endTime, 0, 0, false);
        emit RaffleCreated(raffleId, address(ticket), address(prize), endTime);
    }

    function beginDraw(uint256 raffleId, uint32 gasLimit, uint16 confirmations) external requiresAuth {
        Raffle storage raffle = raffles[raffleId];
        require(raffle.requestId == 0 && !raffle.drawn, "Raffle is already drawn.");
        raffle.requestId = requestRandomness(gasLimit, confirmations, 1);
        emit RaffleStarted(raffleId, raffle.requestId);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        Raffle storage raffle = raffles[raffleRequests[_requestId]];
        raffle.drawn = true;
        unchecked {
            raffle.offset = uint32(_randomWords[0]);
        }
        emit RaffleDrawn(raffleRequests[_requestId], raffle.offset);
    }

    function claimPrize(uint256 raffleId, uint256 tokenId) external payable {
        Raffle memory raffle = raffles[raffleId];
        require(raffle.offset != 0, "Raffle is not drawn yet.");
        uint256 prizeId = (raffle.offset + tokenId) % raffle.ticket.totalSupply();
        _transfer(raffle.ticket, msg.sender, address(this), tokenId);
        _transfer(raffle.prize, address(this), address(this), prizeId);
    }

    function withdraw(NFT nft, uint256 id) external requiresAuth {
        _transfer(nft, address(this), msg.sender, id);
    }

    function _transfer(NFT nft, address from, address to, uint256 id) internal {
        uint256 fee = nft.getTransferFee(id);
        nft.safeTransferFrom{value: fee}(from, to, id);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC721} from "./ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {String} from "../libraries/String.sol";

contract NFT is ERC721, Auth {
    using String for uint256;

    string public baseURI;

    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public transferFee;

    // We allow for internal tiers of tokens to be minted.
    // This can be used to calculate different mint prices for different tiers.
    // This can be side-stepped by always using tierId 0 and not setting maxTierSupply.
    uint256 public tierCount;

    mapping(uint256 tier => uint256 maxSupply) public maxTierSupply;
    mapping(uint256 tier => uint256 supply) public tierMintCount;
    mapping(uint256 tokenId => uint256 tier) public tierOf;

    event SetTransferFee(uint256 transferFee);
    event SetTierSupply(uint256 indexed tier, uint256 maxSupply);
    event SetBaseURI(string baseURI);
    event SetMaxSupply(uint256 maxSupply);

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _authority,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        uint256 _transferFee
    ) ERC721(_name, _symbol) Auth(_owner, Authority(_authority)) {
        baseURI = _baseTokenURI;
        maxSupply = _maxSupply;
        transferFee = _transferFee;
        emit SetBaseURI(_baseTokenURI);
        emit SetMaxSupply(_maxSupply);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < totalSupply, "URI query for nonexistent token");
        return string.concat(baseURI, tokenId.uint2str());
    }

    function getTransferFee(uint256) external view returns (uint256) {
        return transferFee;
    }

    function transferFrom(address from, address to, uint256 id) public payable virtual override {
        require(msg.value >= transferFee, "Insufficient transfer fee");
        super.transferFrom(from, to, id);
    }

    function setTransferFee(uint256 _fee) external requiresAuth {
        transferFee = _fee;
        emit SetTransferFee(_fee);
    }

    // Set max supply for new or existing tier.
    // Once a tier is added it cannot be removed.
    function setTierSupply(uint256 tier, uint256 supply) external requiresAuth {
        require(tier <= tierCount, "Invalid group id");
        if (tier == tierCount) {
            // We are adding a new tier.
            tierCount++;
        }
        maxTierSupply[tier] = supply;
        emit SetTierSupply(tier, supply);
    }

    function setBaseURI(string memory _baseURI) external requiresAuth {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function setMaxSupply(uint256 _maxSupply) external requiresAuth {
        maxSupply = _maxSupply;
        emit SetMaxSupply(_maxSupply);
    }

    function mint(address to, uint256 tier) external requiresAuth returns (uint256 tokenId) {
        require(totalSupply < maxSupply, "Max supply reached");
        if (tierCount > 0) {
            require(tier < tierCount, "Invalid tier");
            require(tierMintCount[tier] < maxTierSupply[tier], "Max group supply reached");
        }
        tokenId = totalSupply++;
        tierMintCount[tier]++;
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not owner of");
        _burn(tokenId);
    }

    function collectFees() external requiresAuth {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {NFT} from "./token/NFT.sol";
import {Auth, Authority, RolesAuthority} from "solmate/auth/authorities/RolesAuthority.sol";

contract Issuer is Auth {
    uint256 public defaultVendorFee = 5e15; // 0.005 ETH
    uint256 public defaultCutBps = 1500; // 15% cut
    uint256 public defaultFee = 1e15; // 0.001 ETH

    struct MintParams {
        uint256 tier;
        uint256 count;
    }

    struct BundleMintParams {
        NFT nft;
        MintParams[] tiers;
    }

    struct VendorFee {
        bool noFlatFee;
        uint64 flatFee;
    }

    struct ProtocolFee {
        bool noFlatFee;
        uint64 flatFee;
        bool noCut;
        uint64 cutBps;
    }

    event SetDefaultFees(uint256 defaultVendorFee, uint256 defaultCutBps, uint256 defaultFee);
    event SetVendorFees(address indexed collection, uint256 tier, uint256 fee);
    event SetProtocolFees(address indexed collection, uint256 tier, uint256 fee, uint256 cut);

    mapping(address user => uint256 balance) public accumulatedFees;
    mapping(NFT collection => mapping(uint256 tier => VendorFee VendorFee)) internal _vendorFees;
    mapping(NFT collection => mapping(uint256 tier => ProtocolFee ProtocolFee)) internal _protocolFees;

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    function deployCollection(
        string memory name,
        string memory symbol,
        address controller,
        string memory baseTokenURI,
        uint256 maxSupply,
        uint256 transferFee
    ) external returns (NFT collection) {
        RolesAuthority authority = new RolesAuthority(address(this), Authority(address(0)));
        collection = new NFT(name, symbol, owner, address(authority), baseTokenURI, maxSupply, transferFee);
        // Role 0 has full control over the collection.
        authority.setRoleCapability(0, address(collection), NFT.setTransferFee.selector, true);
        authority.setRoleCapability(0, address(collection), NFT.setTierSupply.selector, true);
        authority.setRoleCapability(0, address(collection), NFT.setBaseURI.selector, true);
        authority.setRoleCapability(0, address(collection), NFT.setMaxSupply.selector, true);
        authority.setRoleCapability(0, address(collection), NFT.mint.selector, true);
        authority.setRoleCapability(0, address(collection), NFT.collectFees.selector, true);
        authority.setRoleCapability(0, address(this), this.setVendorFee.selector, true);
        // Role 1 has minting rights.
        authority.setRoleCapability(1, address(collection), NFT.mint.selector, true);
        authority.setUserRole(controller, 0, true);
        authority.setUserRole(controller, 1, true);
        authority.setUserRole(address(this), 1, true);
        authority.setOwner(owner);
    }

    function getFees(NFT collection, uint256 tier, uint256 count)
        public
        view
        returns (uint256 totalAmount, uint256 protocolAmount, uint256 vendorAmount)
    {
        ProtocolFee memory protocolFees = _protocolFees[collection][tier];
        VendorFee memory vendorFees = _vendorFees[collection][tier];
        uint256 baseFee = _getValue(protocolFees.noFlatFee, protocolFees.flatFee, defaultFee);
        uint256 vendorFee = _getValue(vendorFees.noFlatFee, vendorFees.flatFee, defaultVendorFee);
        uint256 cutBps = _getValue(protocolFees.noCut, protocolFees.cutBps, defaultCutBps);
        totalAmount = count * (baseFee + vendorFee);
        uint256 cut = vendorFee * cutBps / 10000;
        protocolAmount = count * (baseFee + cut);
        vendorAmount = count * (vendorFee - cut);
    }

    function setDefaultFees(uint256 _defaultVendorFee, uint256 _defaultCutBps, uint256 _defaultFee)
        external
        requiresAuth
    {
        defaultVendorFee = _defaultVendorFee;
        defaultCutBps = _defaultCutBps;
        defaultFee = _defaultFee;
        emit SetDefaultFees(_defaultVendorFee, _defaultCutBps, _defaultFee);
    }

    function setProtocolFee(NFT collection, uint256 tier, uint64 flatFee, uint64 cutBps) external requiresAuth {
        bool noFlatFee = flatFee == 0;
        bool noCut = cutBps == 0;
        _protocolFees[collection][tier] = ProtocolFee(noFlatFee, flatFee, noCut, cutBps);
        emit SetProtocolFees(address(collection), tier, flatFee, cutBps);
    }

    function setVendorFee(NFT collection, uint256 tier, uint64 fee) external {
        require(collection.authority().canCall(msg.sender, address(this), msg.sig), "Unauthorized");
        _vendorFees[collection][tier] = VendorFee(fee == 0, fee);
    }

    function mintToken(NFT collection, address recipient, uint256 tier, uint256 count)
        external
        payable
        returns (uint256[] memory tokenIds)
    {
        (uint256 fee, uint256 protocolFee, uint256 vendorFee) = getFees(collection, tier, count);
        require(msg.value >= fee, "Not enough ETH sent.");
        accumulatedFees[owner] += protocolFee;
        accumulatedFees[collection.owner()] += vendorFee;
        tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = collection.mint(recipient, tier);
        }
    }

    function _getValue(bool isZero, uint256 value, uint256 defaultValue) internal pure returns (uint256) {
        if (isZero) {
            return 0;
        } else if (value == 0) {
            return defaultValue;
        } else {
            return value;
        }
    }

    function collectFees() external {
        uint256 amount = accumulatedFees[msg.sender];
        accumulatedFees[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/interfaces/LinkTokenInterface.sol";
import "../interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public payable virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public payable virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
        }
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public payable virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
        }
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library String {
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Auth, Authority} from "../Auth.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}