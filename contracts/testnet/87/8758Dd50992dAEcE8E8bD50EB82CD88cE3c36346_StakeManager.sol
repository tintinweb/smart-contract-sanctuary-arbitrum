// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;
import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";

import "./PeekABoo.sol";

contract StakeManager is Ownable {
  constructor(address[] memory _services, string[] memory _serviceNames) {
    for (uint256 i = 0; i < _services.length; i++) {
      addService(_services[i], _serviceNames[i]);
    }
  }

  modifier onlyService() {
    bool _isService = false;
    for (uint256 i; i < services.length; i++) {
      if (msg.sender == services[i]) {
        _isService = true;
      }
    }
    require(_isService, "You're not an authorized staking service, you can't make changes.");
    _;
  }

  modifier onlyPeekABoo() {
    require(msg.sender == address(peekaboo), "Only the PeekABoo contract can call this function");
    _;
  }

  address[] services;
  mapping(address => uint256) serviceAddressToIndex;
  mapping(uint256 => address) public tokenIdToStakeService;
  mapping(uint256 => address) public tokenIdToOwner;
  mapping(address => string) public stakeServiceToServiceName;

  mapping(uint256 => uint256) public tokenIdToEnergy;
  mapping(uint256 => uint256) public tokenIdToClaimtime;

  PeekABoo peekaboo;

  function addService(address service, string memory serviceName) public onlyOwner {
    serviceAddressToIndex[service] = services.length;
    stakeServiceToServiceName[service] = serviceName;
    services.push(service);
  }

  function removeService(address service) external onlyOwner {
    require(services.length > 0, "no services to remove");
    uint256 toRemoveIndex = serviceAddressToIndex[service];
    address toRemove = services[toRemoveIndex];
    address _temp = services[services.length - 1];

    services[services.length - 1] = toRemove;
    services[toRemoveIndex] = _temp;

    serviceAddressToIndex[_temp] = toRemoveIndex;
    delete serviceAddressToIndex[service];
    delete stakeServiceToServiceName[service];
    services.pop();
  }

  function stakePABOnService(
    uint256 tokenId,
    address service,
    address owner
  ) external onlyService {
    tokenIdToStakeService[tokenId] = service;
    tokenIdToOwner[tokenId] = owner;
  }

  function isStaked(
    uint256 tokenId,
    address service,
    address owner
  ) external view returns (bool) {
    return tokenIdToStakeService[tokenId] == service && tokenIdToOwner[tokenId] == owner;
  }

  function unstakePeekABoo(uint256 tokenId) external onlyService {
    tokenIdToStakeService[tokenId] = address(0);
    tokenIdToOwner[tokenId] = address(0);
  }

  function getServices() public view returns (address[] memory) {
    return services;
  }

  function isService(address service) public view returns (bool) {
    return (keccak256(abi.encodePacked(stakeServiceToServiceName[service])) != keccak256(abi.encodePacked("")));
  }

  function initializeEnergy(uint256 tokenId) external onlyPeekABoo {
    tokenIdToEnergy[tokenId] = 12;
    tokenIdToClaimtime[tokenId] = block.timestamp;
  }

  function claimEnergy(uint256 tokenId) external {
    uint256 claimable = claimableEnergy(tokenId);
    if (claimable > 0) {
      uint256 carryOver = carryOverTime(tokenId);
      tokenIdToEnergy[tokenId] += claimable;
      tokenIdToClaimtime[tokenId] = block.timestamp - carryOver;
      if (tokenIdToEnergy[tokenId] > 12) tokenIdToEnergy[tokenId] = 12;
    }
  }

  function claimableEnergy(uint256 tokenId) public view returns (uint256) {
    return (block.timestamp - tokenIdToClaimtime[tokenId]) / 2 hours;
  }

  function carryOverTime(uint256 tokenId) public view returns (uint256) {
    return (block.timestamp - tokenIdToClaimtime[tokenId]) % 2 hours;
  }

  function hasEnergy(uint256 tokenId, uint256 amount) public view returns (bool) {
    return tokenIdToEnergy[tokenId] >= amount;
  }

  function useEnergy(uint256 tokenId, uint256 amount) external onlyService {
    require(hasEnergy(tokenId, amount), "No energy");
    tokenIdToEnergy[tokenId] -= amount;
  }

  function setPeekABoo(address _peekaboo) external onlyOwner {
    peekaboo = PeekABoo(_peekaboo);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

library VerifySignature {
  /* 1. Unlock MetaMask account
    ethereum.enable()
    */

  /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
  function getMessageHash(
    address[] memory forAddresses,
    string memory _message,
    uint256 _nonce
  ) public pure returns (bytes32) {
    bytes memory addressesPacked;

    for (uint256 i = 0; i < forAddresses.length; i++) {
      addressesPacked = abi.encodePacked(addressesPacked, forAddresses[i]);
    }

    return keccak256(abi.encodePacked(addressesPacked, _message, _nonce));
  }

  /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
  function verify(
    address _signer,
    address[] memory _forAddresses,
    string memory _message,
    uint256 _nonce,
    bytes memory signature
  ) public pure returns (bool) {
    bytes32 messageHash = getMessageHash(_forAddresses, _message, _nonce);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    return recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    public
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, "invalid signature length");

    assembly {
      /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }

    // implicitly return (r, s, v)
  }
}

// SPDX-License-Identifier: MIT LICENSE
import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "../.deps/npm/@openzeppelin/contracts/utils/Strings.sol";
import "./IPeekABoo.sol";
import "./PeekABoo.sol";
import "./Level.sol";

pragma solidity ^0.8.0;

contract Traits is Ownable {
  using Strings for uint256;

  PeekABoo public peekaboo;

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    string svg;
  }

  // mapping from buster trait type (index) to its name
  // storage of each traits name and base64 PNG data
  mapping(uint256 => mapping(uint256 => Trait))[2] public traitData;

  // ghostOrBuster => traitType => [commonEndIndex, uncommonEndIndex, ...]
  mapping(uint256 => uint256[4])[2] public traitRarityIndex;
  
  constructor(PeekABoo _peekaboo) {
    peekaboo = _peekaboo;
  }

  /** ADMIN */

  /**
   * administrative to upload the names and images associated with each trait
   * @param ghostOrBuster 0 if ghost, 1 if buster
   * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
  function uploadTraits(
    uint256 ghostOrBuster,
    uint256 traitType,
    uint256[] calldata traitIds,
    Trait[] calldata traits
  ) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint256 i = 0; i < traits.length; i++) {
      traitData[ghostOrBuster][traitType][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].svg
      );
    }
  }

  function setPeekABoo(address _peekaboo) external onlyOwner {
    peekaboo = PeekABoo(_peekaboo);
  }

  /** RENDER */
  function drawSVG(
    uint256 tokenId,
    uint256 width,
    uint256 height
  ) public view returns (string memory) {
    IPeekABoo.PeekABooTraits memory _peekaboo = peekaboo.getTokenTraits(
      tokenId
    );
    uint8 peekabooType = _peekaboo.isGhost ? 0 : 1;

    string memory svgString = string(
      abi.encodePacked(
        (traitData[0][0][_peekaboo.background]).svg,
        (traitData[peekabooType][1][_peekaboo.back]).svg,
        (traitData[peekabooType][2][_peekaboo.bodyColor]).svg,
        _peekaboo.isGhost
          ? (traitData[peekabooType][3][_peekaboo.clothesOrHelmet]).svg
          : (traitData[peekabooType][3][_peekaboo.hat]).svg,
        _peekaboo.isGhost
          ? (traitData[peekabooType][4][_peekaboo.hat]).svg
          : (traitData[peekabooType][4][_peekaboo.face]).svg,
        _peekaboo.isGhost
          ? (traitData[peekabooType][5][_peekaboo.face]).svg
          : (traitData[peekabooType][5][_peekaboo.clothesOrHelmet]).svg,
        _peekaboo.isGhost
          ? (traitData[peekabooType][6][_peekaboo.hands]).svg
          : ""
      )
    );

    return
      string(
        abi.encodePacked(
          '<svg width="100%"',
          ' height="100%" viewBox="0 0 100 100"',
          ">",
          svgString,
          "</svg>"
        )
      );
  }

  function tryOutTraits(
    uint256 tokenId,
    uint256[2][] memory traitsToTry,
    uint256 width,
    uint256 height
  ) public view returns (string memory) {
    IPeekABoo.PeekABooTraits memory _peekaboo = peekaboo.getTokenTraits(
      tokenId
    );
    uint8 peekabooType = _peekaboo.isGhost ? 0 : 1;
    require(traitsToTry.length <= 7, "Trying too many traits");

    string[7] memory traits = [
      (traitData[0][0][_peekaboo.background]).svg,
      (traitData[peekabooType][1][_peekaboo.back]).svg,
      (traitData[peekabooType][2][_peekaboo.bodyColor]).svg,
      _peekaboo.isGhost
        ? (traitData[peekabooType][3][_peekaboo.clothesOrHelmet]).svg
        : (traitData[peekabooType][3][_peekaboo.hat]).svg,
      _peekaboo.isGhost
        ? (traitData[peekabooType][4][_peekaboo.hat]).svg
        : (traitData[peekabooType][4][_peekaboo.face]).svg,
      _peekaboo.isGhost
        ? (traitData[peekabooType][5][_peekaboo.face]).svg
        : (traitData[peekabooType][5][_peekaboo.clothesOrHelmet]).svg,
      _peekaboo.isGhost ? (traitData[peekabooType][6][_peekaboo.hands]).svg : ""
    ];

    for (uint256 i = 0; i < traitsToTry.length; i++) {
      if (traitsToTry[i][0] == 0) {
        traits[0] = (traitData[0][0][traitsToTry[i][1]]).svg;
      } else if (traitsToTry[i][0] == 1) {
        traits[1] = (traitData[peekabooType][1][traitsToTry[i][1]]).svg;
      } else if (traitsToTry[i][0] == 2) {
        traits[2] = (traitData[peekabooType][2][traitsToTry[i][1]]).svg;
      } else if (traitsToTry[i][0] == 3) {
        traits[3] = (traitData[peekabooType][3][traitsToTry[i][1]]).svg;
      } else if (traitsToTry[i][0] == 4) {
        traits[4] = (traitData[peekabooType][4][traitsToTry[i][1]]).svg;
      } else if (traitsToTry[i][0] == 5) {
        traits[5] = (traitData[peekabooType][5][traitsToTry[i][1]]).svg;
      } else if (traitsToTry[i][0] == 6) {
        traits[6] = (traitData[peekabooType][6][traitsToTry[i][1]]).svg;
      }
    }

    string memory svgString = string(
      abi.encodePacked(
        traits[0],
        traits[1],
        traits[2],
        traits[3],
        traits[4],
        traits[5],
        _peekaboo.isGhost ? traits[6] : ""
      )
    );

    return
      string(
        abi.encodePacked(
          '<svg width="100%"',
          // Strings.toString(width),
          ' height="100%" viewBox="0 0 100 100"',
          // Strings.toString(height),
          ">",
          svgString,
          "</svg>"
        )
      );
  }

  function attributeForTypeAndValue(
    string memory traitType,
    string memory value
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":"',
          value,
          '"}'
        )
      );
  }

  function attributeForTypeAndValue(string memory traitType, uint64 value)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":"',
          uint256(value).toString(),
          '"}'
        )
      );
  }

  function compileAttributes(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    IPeekABoo.PeekABooTraits memory attr = peekaboo.getTokenTraits(tokenId);

    string memory traits;
    if (attr.isGhost) {
      traits = string(
        abi.encodePacked(
          attributeForTypeAndValue(
            "Background",
            traitData[0][0][attr.background].name
          ),
          ",",
          attributeForTypeAndValue("Back", traitData[0][1][attr.back].name),
          ",",
          attributeForTypeAndValue(
            "BodyColor",
            traitData[0][2][attr.bodyColor].name
          ),
          ",",
          attributeForTypeAndValue(
            "Clothes",
            traitData[0][3][attr.clothesOrHelmet].name
          ),
          ",",
          attributeForTypeAndValue("Hat", traitData[0][4][attr.hat].name),
          ",",
          attributeForTypeAndValue("Face", traitData[0][5][attr.face].name),
          ",",
          attributeForTypeAndValue("Hands", traitData[0][6][attr.hands].name),
          ",",
          attributeForTypeAndValue("Tier", attr.tier),
          ",",
          attributeForTypeAndValue("Level", attr.level)
        )
      );
    } else {
      traits = string(
        abi.encodePacked(
          attributeForTypeAndValue(
            "Background",
            traitData[0][0][attr.background].name
          ),
          ",",
          attributeForTypeAndValue("Back", traitData[1][1][attr.back].name),
          ",",
          attributeForTypeAndValue(
            "BodyColor",
            traitData[1][2][attr.bodyColor].name
          ),
          ",",
          attributeForTypeAndValue("Hat", traitData[1][3][attr.hat].name),
          ",",
          attributeForTypeAndValue("Face", traitData[1][4][attr.face].name),
          ",",
          attributeForTypeAndValue(
            "Helmet",
            traitData[1][5][attr.clothesOrHelmet].name
          ),
          ",",
          attributeForTypeAndValue("Tier", attr.tier),
          ",",
          attributeForTypeAndValue("Level", attr.level)
        )
      );
    }
    return
      string(
        abi.encodePacked(
          "[",
          traits,
          '{"trait_type":"Type","value":',
          attr.isGhost ? '"Ghost"' : '"Buster"',
          "}]"
        )
      );
  }

  function compileAttributesAsIDs(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    IPeekABoo.PeekABooTraits memory attr = peekaboo.getTokenTraits(tokenId);

    string memory traits;
    if (attr.isGhost) {
      traits = string(
        abi.encodePacked(
          attributeForTypeAndValue("Background", attr.background.toString()),
          ",",
          attributeForTypeAndValue("Back", attr.back.toString()),
          ",",
          attributeForTypeAndValue("BodyColor", attr.bodyColor.toString()),
          ",",
          attributeForTypeAndValue("Clothes", attr.clothesOrHelmet.toString()),
          ",",
          attributeForTypeAndValue("Hat", attr.hat.toString()),
          ",",
          attributeForTypeAndValue("Face", attr.face.toString()),
          ",",
          attributeForTypeAndValue("Hands", attr.hands.toString()),
          ","
        )
      );
    } else {
      traits = string(
        abi.encodePacked(
          attributeForTypeAndValue("Background", attr.background.toString()),
          ",",
          attributeForTypeAndValue("Back", attr.back.toString()),
          ",",
          attributeForTypeAndValue("BodyColor", attr.bodyColor.toString()),
          ",",
          attributeForTypeAndValue("Hat", attr.hat.toString()),
          ",",
          attributeForTypeAndValue("Face", attr.face.toString()),
          ",",
          attributeForTypeAndValue("Helmet", attr.clothesOrHelmet.toString()),
          ","
        )
      );
    }
    return
      string(
        abi.encodePacked(
          "[",
          traits,
          '{"trait_type":"Type","value":',
          attr.isGhost ? '"Ghost"' : '"Buster"',
          "}]"
        )
      );
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    IPeekABoo.PeekABooTraits memory attr = peekaboo.getTokenTraits(tokenId);

    string memory metadata = string(
      abi.encodePacked(
        '{"name": "',
        attr.isGhost ? "Ghost #" : "Buster #",
        tokenId.toString(),
        '", "description": "Ghosts have come out to haunt the metaverse as the night awakes, Busters scramble to purge these ghosts and claim the bounties. Ghosts are accumulating $BOO, amassing it to grow their haunted grounds. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. With the help of Oracles we remove exploits regarding randomness that would otherwise ruin the project. The project is built on the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
        bytes(drawSVG(tokenId, 512, 512)),
        '", "attributes":',
        compileAttributes(tokenId),
        "}"
      )
    );

    return
      string(
        abi.encodePacked("data:application/json;base64,", bytes(metadata))
      );
  }

  function setRarityIndex(
    uint256 ghostOrBuster,
    uint256 traitType,
    uint256[4] calldata traitIndices
  ) external onlyOwner {
    for (uint256 i = 0; i < 4; i++) {
      traitRarityIndex[ghostOrBuster][traitType][i] = traitIndices[i];
    }
  }

  function getRarityIndex(
    uint256 ghostOrBuster,
    uint256 traitType,
    uint256 rarity
  ) public returns (uint256) {
    return traitRarityIndex[ghostOrBuster][traitType][rarity];
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "../.deps/npm/@openzeppelin/contracts/security/Pausable.sol";
import "../.deps/npm/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../.deps/npm/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPeekABoo.sol";
import "./Traits.sol";
import "./Level.sol";
import "./BOO.sol";
import "./Developers.sol";
import "./StakeManager.sol";
import "./InGame.sol";

contract PeekABoo is IPeekABoo, ERC721Enumerable, Ownable, Pausable, Developers {
  uint256 public immutable MAX_PHASE1_TOKENS;
  uint256 public immutable MAX_PHASE2_TOKENS;
  uint256 public immutable MAX_NUM_PHASE1_GHOSTS;
  uint256 public immutable MAX_NUM_PHASE1_BUSTERS;
  uint256 public immutable MAX_NUM_PHASE2_GHOSTS;
  uint256 public immutable MAX_NUM_PHASE2_BUSTERS;
  uint256 public phase2Price;
  uint256 public phase2PriceRate;
  // number of tokens have been minted so far
  uint256 public phase1Minted;
  uint256 public phase2Minted;
  uint256 public communnityNonce;
  uint256 public traitPriceRate;
  uint256 public abilityPriceRate;

  // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => PeekABooTraits) public tokenTraits;
  mapping(uint256 => bool[6]) public boughtAbilities;
  // tokenId => boughtTraitCountByRarity [common,uncommon,...]
  mapping(uint256 => uint256[4]) public boughtTraitCount;
  mapping(uint256 => GhostMap) public ghostMaps;
  mapping(address => uint256) public whitelist;
  mapping(address => uint256[]) public addressToTokens;

  // reference to $BOO for burning on mint
  BOO public boo;
  IERC20 public magic;
  Traits public traits;
  Level public level;
  InGame public ingame;
  StakeManager public stakeManager;

  modifier onlyLevel {
    require(_msgSender() == address(level));
    _;
  }

  modifier onlyInGame {
    require(_msgSender() == address(ingame));
    _;
  }

  event PABMinted(bytes32 indexed requestId, uint256 amount, uint256 indexed result);

  constructor(BOO _boo, address[] memory initDevelopers) ERC721("PeekABoo", "PAB") Developers(initDevelopers) {
    boo = _boo;
    MAX_PHASE1_TOKENS = 10000;
    MAX_PHASE2_TOKENS = 10000;
    MAX_NUM_PHASE1_GHOSTS = 2500;
    MAX_NUM_PHASE1_BUSTERS = 7500;
    MAX_NUM_PHASE2_GHOSTS = 2500;
    MAX_NUM_PHASE2_BUSTERS = 7500;

    for (uint256 i = 0; i < developers.length; i++) {
      whitelist[developers[i]] = 400;
    }
  }

  function pseudoRandomizeCommonTraits(uint256 tokenId, uint256 tokenType) public {
    tokenTraits[tokenId].owner = _msgSender();
    uint256 randomizedCommon = uint256(
      keccak256(abi.encodePacked(_msgSender(), tokenId, block.timestamp, tokenType * 666, block.difficulty))
    );

    if (tokenType == 0) {
      tokenTraits[tokenId].isGhost = true;
      setTokenTraits(tokenId, 0, randomizedCommon % 7);
      setTokenTraits(tokenId, 1, randomizedCommon % 9);
      setTokenTraits(tokenId, 2, randomizedCommon % 8);
      setTokenTraits(tokenId, 3, randomizedCommon % 14);
      setTokenTraits(tokenId, 4, randomizedCommon % 13);
      setTokenTraits(tokenId, 5, randomizedCommon % 7);
      setTokenTraits(tokenId, 6, randomizedCommon % 7);
    } else {
      tokenTraits[tokenId].isGhost = false;
      setTokenTraits(tokenId, 0, randomizedCommon % 7);
      setTokenTraits(tokenId, 1, randomizedCommon % 5);
      setTokenTraits(tokenId, 2, randomizedCommon % 12);
      setTokenTraits(tokenId, 3, randomizedCommon % 10);
      setTokenTraits(tokenId, 4, randomizedCommon % 4);
      setTokenTraits(tokenId, 5, randomizedCommon % 2);
    }

    tokenTraits[tokenId].level = 1;
    tokenTraits[tokenId].tier = 0;
  }

  function developerInitMint() external onlyDeveloper {
    uint256 mintCountPerCall = 40;
    uint256 devAmount = whitelist[_msgSender()];

    if (devAmount > 0 && devAmount < mintCountPerCall) {
      mintCountPerCall = devAmount;
    }
    whitelist[_msgSender()] = devAmount - mintCountPerCall;

    for (uint256 j = 0; j < mintCountPerCall; j++) {
      _safeMint(_msgSender(), phase1Minted);
      addressToTokens[_msgSender()].push(phase1Minted);
      // if (j < 3) {
      //   pseudoRandomizeCommonTraits(minted, 0);
      // }
      // else {
      //   pseudoRandomizeCommonTraits(minted, 1);
      // }
      phase1Minted++;
    }
  }

  function mint(uint256[] memory types) external payable {
    require(tx.origin == _msgSender(), "Only EOA");
    require(isWhitelisted(_msgSender()), "not whitelisted");

    uint256 amount = whitelist[_msgSender()];
    require(phase1Minted + amount <= MAX_PHASE1_TOKENS, "All Phase 1 tokens minted");
    require(amount == types.length, "length of types does not match amount");
    delete whitelist[_msgSender()];

    StakeManager stakeManagerRef = stakeManager;

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(_msgSender(), phase1Minted);
      addressToTokens[_msgSender()].push(phase1Minted);
      stakeManagerRef.initializeEnergy(phase1Minted);
      pseudoRandomizeCommonTraits(phase1Minted, types[i]);
      phase1Minted++;
    }
  }

  function mintPhase2(
    uint256 tokenId,
    uint256[] memory types,
    uint256 amount,
    uint256 booAmount
  ) external payable {
    require(_msgSender() == tokenTraits[tokenId].owner, "Only owner can mint Phase 2");
    require(phase2Minted + amount <= MAX_PHASE2_TOKENS, "All Phase 2 tokens minted");
    require(amount == types.length, "length of types does not match amount");
    require(tokenTraits[tokenId].level % 10 == 0, "Phase 2 cannot be minted yet by this token");
    require(
      tokenTraits[tokenId].phase2Minted[tokenTraits[tokenId].level / 10] == false,
      "Already claimed for this level"
    );
    require(amount == tokenTraits[tokenId].level / 10, "Cannot mint this many at this level");
    require(booAmount >= phase2Price * amount, "Not enough $BOO to mint this many tokens");
    require(tokenTraits[tokenId].level / 10 > tokenTraits[tokenId].tier, "Cannot mint after tier up");
    uint256 allowance = boo.allowance(msg.sender, address(this));
    require(allowance >= booAmount, "Check the token allowance");
    approveBOO(booAmount);
    boo.transferFrom(msg.sender, address(this), booAmount);
    tokenTraits[tokenId].phase2Minted[tokenTraits[tokenId].level / 10] = true;
    tokenTraits[tokenId].level = tokenTraits[tokenId].level - 5;
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(_msgSender(), 9999 + phase2Minted);
      pseudoRandomizeCommonTraits(9999 + phase2Minted, types[i]);
      phase2Minted++;
    }
    phase2Price = phase2Price + (phase2PriceRate * (phase2Minted / 1000));
  }

  function incrementTier(uint256 tokenId) external onlyInGame {
    tokenTraits[tokenId].tier++;
  }

  function addWhitelist(address[] memory addresses, uint256[] memory amount) external onlyDeveloper {
    require(addresses.length == amount.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = amount[i];
    }
  }

  function incrementLevel(uint256 tokenId) public onlyLevel {
    tokenTraits[tokenId].level++;
  }

  function setTokenTraits(
    uint256 tokenId,
    uint256 traitType,
    uint256 traitId
  ) public {
    require(_msgSender() == tokenTraits[tokenId].owner, "Not owner");
    require(level.isUnlocked(tokenId, traitType, traitId), "This trait is not unlocked.");

    if (tokenTraits[tokenId].isGhost) {
      // Check if trait is common or is bought
      require(
        (traitId <= traits.getRarityIndex(0, traitType, 0)) ||
          (ingame.isBoughtTrait(tokenId, traitType, traitId) == true),
        "cannot equip this trait"
      );
      if (traitType == 0) tokenTraits[tokenId].background = traitId;
      else if (traitType == 1) tokenTraits[tokenId].back = traitId;
      else if (traitType == 2) tokenTraits[tokenId].bodyColor = traitId;
      else if (traitType == 3) tokenTraits[tokenId].clothesOrHelmet = traitId;
      else if (traitType == 4) tokenTraits[tokenId].hat = traitId;
      else if (traitType == 5) tokenTraits[tokenId].face = traitId;
      else if (traitType == 6) tokenTraits[tokenId].hands = traitId;
    } else {
      // Check if trait is common or is bought
      require(
        (traitId <= traits.getRarityIndex(1, traitType, 0)) ||
          (ingame.isBoughtTrait(tokenId, traitType, traitId) == true),
        "cannot equip this trait"
      );
      if (traitType == 0) tokenTraits[tokenId].background = traitId;
      else if (traitType == 1) tokenTraits[tokenId].back = traitId;
      else if (traitType == 2) tokenTraits[tokenId].bodyColor = traitId;
      else if (traitType == 3) tokenTraits[tokenId].hat = traitId;
      else if (traitType == 4) tokenTraits[tokenId].face = traitId;
      else if (traitType == 5) tokenTraits[tokenId].clothesOrHelmet = traitId;
    }
  }

  function setMultipleTokenTraits(
    uint256 tokenId,
    uint256[] calldata traitTypes,
    uint256[] calldata traitIds
  ) external {
    require(traitTypes.length == traitIds.length, "Incorrect lengths");
    for (uint256 i = 0; i < traitTypes.length; i++) {
      setTokenTraits(tokenId, traitTypes[i], traitIds[i]);
    }
  }

  function initializeGhostMap(uint256 tokenId, uint256 nonce) external {
    communnityNonce += nonce;
    uint256 _cn = communnityNonce;
    require(!ghostMaps[tokenId].initialized, "already initialized the map.");
    for (uint256 j = 0; j < 10; j++) {
      for (uint256 k = 0; k < 10; k++) {
        if (uint256(keccak256(abi.encodePacked(tokenId, _cn, j, k))) % 10 == 1) {
          ghostMaps[tokenId].grid[j][k] = 1;
        }
      }
    }
    ghostMaps[tokenId].gridSize = 8;
    ghostMaps[tokenId].difficulty = 0;
    ghostMaps[tokenId].initialized = true;
  }

  /** ADMIN */

  function getPhase1Minted() public view returns (uint256 result) {
    result = phase1Minted;
  }

  function getPhase2Minted() public view returns (uint256 result) {
    result = phase2Minted;
  }

  function setBOO(address _boo) external onlyOwner {
    boo = BOO(_boo);
  }

  function setStakeManager(address _stakeManager) external onlyOwner {
    stakeManager = StakeManager(_stakeManager);
  }

  function setTraits(address _traits) external onlyOwner {
    traits = Traits(_traits);
  }

  function setLevel(address _level) external onlyOwner {
    level = Level(_level);
  }

  function setInGame(address _ingame) external onlyOwner {
    ingame = InGame(_ingame);
  }

  function setPhase2Price(uint256 _price) external onlyOwner {
    phase2Price = _price;
  }

  function setPhase2Rate(uint256 _rate) external onlyOwner {
    phase2PriceRate = _rate;
  }

  function setTraitPriceRate(uint256 _rate) external onlyOwner {
    traitPriceRate = _rate;
  }

  function setMagic(address _magic) external onlyOwner {
    magic = IERC20(_magic);
  }

  function setAbilityPriceRate(uint256 _rate) external onlyOwner {
    abilityPriceRate = _rate;
  }

  /** PUBLIC */

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return "";
  }

  function getTokenTraits(uint256 tokenId) public view returns (PeekABooTraits memory) {
    return tokenTraits[tokenId];
  }

  function getGhostMapGridFromTokenId(uint256 tokenId) external view returns (GhostMap memory) {
    return ghostMaps[tokenId];
  }

  function getTokens() public view returns (uint256[] memory) {
    return addressToTokens[_msgSender()];
  }

  function isWhitelisted(address _address) public view returns (bool) {
    return whitelist[_address] > 0;
  }

  function approveBOO(uint256 _tokenamount) public returns (bool) {
    boo.approve(address(this), _tokenamount);
    return true;
  }

  function getApprovedBOO() public view returns (uint256 allowance) {
    allowance = boo.allowance(msg.sender, address(this));
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../.deps/npm/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "../.deps/npm/@openzeppelin/contracts/security/Pausable.sol";
import "./PeekABoo.sol";
import "./BOO.sol";
import "./StakeManager.sol";

contract PABStake is Ownable, IERC721Receiver, Pausable {
  // struct to store a pabstake's token, owner, and earning values
  struct PeekABooNormalStaked {
    uint256 tokenId;
    uint256 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event PeekABooClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event PeekABooRescued(address owner, uint256 tokenId);
  event Debug1(uint256 earnedAmount);

  // reference to the PeekABoo NFT contract
  PeekABoo public peekaboo;
  // reference to the $BOO contract for minting $BOO earnings
  BOO public boo;
  StakeManager public sm;

  // maps tokenId to pabstake
  mapping(uint256 => PeekABooNormalStaked) public pabstake;
  // any rewards distributed when no Busters are staked
  uint256 public unaccountedRewards = 0;

  // Ghost earn $BOO everyday day relative to their tier
  uint256[6] public DAILY_BOO_RATE;
  uint256 public EMISSION_RATE;
  // Ghost must have 1 days worth of $BOO to unstake
  uint256 public constant MINIMUM_TO_EXIT = 1 days;
  // there will only ever be (roughly) 666 million $BOO earned through staking
  uint256 public constant MAXIMUM_GLOBAL_BOO = 666000000 ether;

  // amount of $BOO earned so far
  uint256 public totalBooEarned;
  // amount of PeekABoos Normal Staked
  uint256 public totalPeekABooStaked;
  // the last time $BOO was claimed
  uint256 public lastClaimTimestamp;
  // the amount of boo that has been taxed total
  uint256 public totalTaxedBoo = 0;

  // emergency rescue to allow unstaking without any checks but without $BOO
  bool public rescueEnabled = false;

  /**
   * @param _peekaboo reference to the PeekABoo NFT contract
   * @param _BOO reference to the $BOO token
   */
  constructor(
    address _peekaboo,
    address _BOO,
    uint256[6] memory _daily_boo_reward_rate
  ) {
    peekaboo = PeekABoo(_peekaboo);
    boo = BOO(_BOO);
    DAILY_BOO_RATE = _daily_boo_reward_rate;
    EMISSION_RATE = 2;
  }

  /** STAKING */

  function normalStakePeekABoos(uint16[] calldata tokenIds) external {
    require(tx.origin == _msgSender(), "No SmartContracts");
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(
        peekabooRef.ownerOf(tokenIds[i]) == _msgSender() || smRef.tokenIdToOwner(tokenIds[i]) == _msgSender(),
        "Not your token"
      );
      sm.stakePABOnService(tokenIds[i], address(this), _msgSender());
      addPeekABoo(_msgSender(), tokenIds[i]);
      peekabooRef.transferFrom(_msgSender(), address(this), tokenIds[i]);
    }
  }

  function addPeekABoo(address account, uint256 tokenId) internal whenNotPaused {
    pabstake[tokenId] = PeekABooNormalStaked({ tokenId: tokenId, value: block.timestamp, owner: account });
    totalPeekABooStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /** CLAIMING / UNSTAKING */

  function claimMany(uint16[] calldata tokenIds) external whenNotPaused {
    uint256 tobePaid = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tobePaid += claimPeekABoo(tokenIds[i], false);
    }
    if (tobePaid == 0) return;
    totalBooEarned += tobePaid;
    boo.mint(_msgSender(), tobePaid);
  }

  function unstakeMany(uint16[] calldata tokenIds) external whenNotPaused {
    uint256 tobePaid = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tobePaid += claimPeekABoo(tokenIds[i], true);
    }
    if (tobePaid == 0) return;
    totalBooEarned += tobePaid;
    boo.mint(_msgSender(), tobePaid);
  }

  function claimPeekABoo(uint256 tokenId, bool unstake) internal virtual returns (uint256 toBePaid) {
    PeekABooNormalStaked memory peekabooStaked = pabstake[tokenId];
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;

    require(
      smRef.tokenIdToOwner(tokenId) == _msgSender() &&
        peekabooRef.ownerOf(tokenId) == address(this) &&
        peekabooStaked.value > 0,
      "Not Staked"
    );
    require(block.timestamp - peekabooStaked.value >= MINIMUM_TO_EXIT, "Must have atleast 1 day worth of $BOO");
    uint256 emission = 100 - ((EMISSION_RATE * peekabooRef.getPhase2Minted()) / 1000);
    if (totalBooEarned < MAXIMUM_GLOBAL_BOO) {
      toBePaid =
        (((block.timestamp - peekabooStaked.value) *
          DAILY_BOO_RATE[peekabooRef.getTokenTraits(tokenId).tier] *
          emission) / 100) /
        1 days;
    } else if (peekabooStaked.value > lastClaimTimestamp) {
      toBePaid = 0; // $BOO production stopped already
    } else {
      toBePaid =
        (((lastClaimTimestamp - peekabooStaked.value) *
          DAILY_BOO_RATE[peekabooRef.getTokenTraits(tokenId).tier] *
          emission) / 100) /
        1 days; // stop earning additional $BOO if it's all been earned
    }

    if (unstake) {
      peekabooRef.transferFrom(address(this), _msgSender(), tokenId); // send back Ghost
      smRef.unstakePeekABoo(tokenId);
      delete pabstake[tokenId];
    } else {
      pabstake[tokenId] = PeekABooNormalStaked({ owner: _msgSender(), tokenId: tokenId, value: block.timestamp }); // reset pabstake
    }
    emit PeekABooClaimed(tokenId, toBePaid, unstake);
  }

  function rescue(uint256[] calldata tokenIds) external {
    require(rescueEnabled, "Rescue is not enabled.");
    PeekABooNormalStaked memory peekabooStaked;
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      peekabooStaked = pabstake[tokenIds[i]];
      require(smRef.tokenIdToOwner(tokenIds[i]) == _msgSender(), "Not your token");

      delete pabstake[tokenIds[i]]; // Delete old mapping
      peekabooRef.transferFrom(address(this), _msgSender(), tokenIds[i]); // Send back PeekABoo
      totalPeekABooStaked -= 1;
      emit PeekABooRescued(_msgSender(), tokenIds[i]);
    }
  }

  /** ACCOUNTING */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setDailyBOORate(uint256[6] memory _daily_boo_reward_rate) external onlyOwner {
    DAILY_BOO_RATE = _daily_boo_reward_rate;
  }

  function setBOO(address _boo) public onlyOwner {
    boo = BOO(_boo);
  }

  function setPeekABoo(address _peekaboo) public onlyOwner {
    peekaboo = PeekABoo(_peekaboo);
  }

  function setStakeManager(address _sm) public onlyOwner {
    sm = StakeManager(_sm);
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send tokens to PABStake directly");
    return IERC721Receiver.onERC721Received.selector;
  }

  function canClaimGhost(uint256 tokenId) public view returns (bool) {
    require(peekaboo.getTokenTraits(tokenId).isGhost, "Not a ghost");
    return block.timestamp - pabstake[tokenId].value >= 1 days;
  }

  function getTimestamp(uint256[] calldata tokenIds) public view returns (uint256[] memory) {
    uint256[] memory timestamps = new uint256[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      timestamps[i] = (pabstake[tokenIds[i]].value);
    }
    return timestamps;
  }

  function getPeekABooValue(uint256[] calldata tokenIds) public view virtual returns (uint256[] memory) {
    PeekABoo peekabooRef = peekaboo;
    uint256[] memory timestamps = getTimestamp(tokenIds);
    uint256[] memory values = new uint256[](tokenIds.length);
    uint256 toBePaid;
    uint256 emission = 100 - ((EMISSION_RATE * peekabooRef.getPhase2Minted()) / 1000);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(timestamps[i] > 0, "Not staked");
      if (totalBooEarned < MAXIMUM_GLOBAL_BOO) {
        toBePaid =
          (((block.timestamp - timestamps[i]) *
            DAILY_BOO_RATE[peekabooRef.getTokenTraits(tokenIds[i]).tier] *
            emission) / 100) /
          1 days;
      } else if (timestamps[i] > lastClaimTimestamp) {
        toBePaid = 0; // $BOO production stopped already
      } else {
        toBePaid =
          (((lastClaimTimestamp - timestamps[i]) *
            DAILY_BOO_RATE[peekabooRef.getTokenTraits(tokenIds[i]).tier] *
            emission) / 100) /
          1 days; // stop earning additional $BOO if it's all been earned
      }
      values[i] = toBePaid;
    }
    return values;
  }

  function setEmissionRate(uint256 _emission) external onlyOwner {
    EMISSION_RATE = _emission;
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "../.deps/npm/@openzeppelin/contracts/security/Pausable.sol";
import "./PeekABoo.sol";
import "./HideNSeek.sol";

contract Level is Ownable, Pausable {
  uint256 immutable BASE_EXP = 10;
  uint256 EXP_GROWTH_RATE1 = 11;
  uint256 EXP_GROWTH_RATE2 = 10;

  mapping(uint256 => uint256) public tokenIdToEXP;
  mapping(uint256 => uint256) public difficultyToEXP;
  mapping(uint256 => mapping(uint256 => uint256)) public unlockedTraits;

  event LevelUp(uint256 tokenId);

  PeekABoo public peekaboo;
  StakeManager public stakeManager;

  constructor(PeekABoo _peekaboo) {
    peekaboo = _peekaboo;
    difficultyToEXP[0] = 1;
    difficultyToEXP[1] = 2;
    difficultyToEXP[2] = 4;
  }

  modifier onlyService {
    require(stakeManager.isService(_msgSender()), "Must be a service, don't cheat");
    _;
  }

  function updateExp(
    uint256 tokenId,
    bool won,
    uint256 difficulty
  ) public onlyService {
    uint256 tokenExp = tokenIdToEXP[tokenId];
    uint256 _expRequired = expRequired(tokenId);
    uint256 expGained;
    if (won) {
      expGained = (difficultyToEXP[difficulty] * 4);
    } else {
      expGained = difficultyToEXP[difficulty];
    }
    PeekABoo peekabooRef = peekaboo;

    if (tokenExp + expGained >= _expRequired) {
      /* Leveled Up */
      emit LevelUp(tokenId);
      tokenIdToEXP[tokenId] = (tokenExp + expGained) - _expRequired;
      peekabooRef.incrementLevel(tokenId);
      unlockTrait(tokenId, peekabooRef.getTokenTraits(tokenId).level);
    } else {
      tokenIdToEXP[tokenId] += expGained;
    }
  }

  function expAmount(uint256 tokenId) public view returns (uint256) {
    return tokenIdToEXP[tokenId];
  }

  function expRequired(uint256 tokenId) public returns (uint256) {
    PeekABoo peekabooRef = peekaboo;
    uint256 levelRequirement = peekabooRef.getTokenTraits(tokenId).level;
    return (BASE_EXP * growthRate(levelRequirement)) / growthRate2(levelRequirement);
  }

  function growthRate(uint256 level) internal returns (uint256) {
    return uint256(EXP_GROWTH_RATE1)**uint256(level - 1);
  }

  function growthRate2(uint256 level) internal returns (uint256) {
    return uint256(EXP_GROWTH_RATE2)**uint256(level - 1);
  }

  function unlockTrait(uint256 tokenId, uint64 level) internal {
    bool _isGhost = peekaboo.getTokenTraits(tokenId).isGhost;
    if (level == 2) {
      unlockedTraits[tokenId][0] = 10;
    } else if (_isGhost) {
      if (level == 3) unlockedTraits[tokenId][1] = 10;
      else if (level == 4) unlockedTraits[tokenId][2] = 10;
      else if (level == 5) unlockedTraits[tokenId][3] = 16;
      else if (level == 6) unlockedTraits[tokenId][4] = 14;
      else if (level == 7) unlockedTraits[tokenId][5] = 8;
      else if (level == 8) unlockedTraits[tokenId][6] = 10;
      else if (level == 9) unlockedTraits[tokenId][1] = 12;
      else if (level == 10) unlockedTraits[tokenId][2] = 13;
      else if (level == 11) unlockedTraits[tokenId][3] = 20;
      else if (level == 12) unlockedTraits[tokenId][4] = 17;
      else if (level == 13) unlockedTraits[tokenId][5] = 10;
      else if (level == 14) unlockedTraits[tokenId][6] = 13;
      else if (level == 15) unlockedTraits[tokenId][1] = 13;
      else if (level == 16) unlockedTraits[tokenId][3] = 22;
      else if (level == 17) unlockedTraits[tokenId][4] = 19;
      else if (level == 18) unlockedTraits[tokenId][5] = 14;
      else if (level == 19) unlockedTraits[tokenId][6] = 14;
      else if (level == 20) unlockedTraits[tokenId][4] = 24;
      else if (level == 21) unlockedTraits[tokenId][4] = 28;
      else if (level == 22) unlockedTraits[tokenId][4] = 30;
      else if (level == 23) unlockedTraits[tokenId][0] = 12;
      else if (level == 24) unlockedTraits[tokenId][1] = 16;
      else if (level == 25) unlockedTraits[tokenId][2] = 16;
      else if (level == 26) unlockedTraits[tokenId][3] = 25;
      else if (level == 27) unlockedTraits[tokenId][4] = 34;
      else if (level == 28) unlockedTraits[tokenId][5] = 17;
      else if (level == 29) unlockedTraits[tokenId][6] = 19;
      else if (level == 30) unlockedTraits[tokenId][0] = 14;
      else if (level == 31) unlockedTraits[tokenId][1] = 18;
      else if (level == 32) unlockedTraits[tokenId][3] = 28;
      else if (level == 33) unlockedTraits[tokenId][4] = 39;
      else if (level == 34) unlockedTraits[tokenId][5] = 19;
      else if (level == 35) unlockedTraits[tokenId][0] = 15;
      else if (level == 36) unlockedTraits[tokenId][5] = 21;
      else if (level == 37) unlockedTraits[tokenId][6] = 23;
      else if (level == 38) unlockedTraits[tokenId][0] = 16;
      else if (level == 39) unlockedTraits[tokenId][1] = 21;
      else if (level == 40) unlockedTraits[tokenId][2] = 18;
      else if (level == 41) unlockedTraits[tokenId][3] = 30;
      else if (level == 42) unlockedTraits[tokenId][4] = 41;
      else if (level == 43) unlockedTraits[tokenId][5] = 23;
      else if (level == 44) unlockedTraits[tokenId][6] = 27;
      else if (level == 45) unlockedTraits[tokenId][0] = 17;
      else if (level == 46) unlockedTraits[tokenId][1] = 31;
      else if (level == 47) unlockedTraits[tokenId][0] = 18;
      else if (level == 48) unlockedTraits[tokenId][4] = 44;
      else if (level == 49) unlockedTraits[tokenId][6] = 28;
      else if (level == 50) unlockedTraits[tokenId][0] = 20;
    } else {
      if (level == 3) unlockedTraits[tokenId][1] = 7;
      else if (level == 4) unlockedTraits[tokenId][2] = 13;
      else if (level == 5) unlockedTraits[tokenId][3] = 10;
      else if (level == 6) unlockedTraits[tokenId][4] = 4;
      else if (level == 7) unlockedTraits[tokenId][5] = 4;
      else if (level == 8) unlockedTraits[tokenId][1] = 10;
      else if (level == 9) unlockedTraits[tokenId][2] = 14;
      else if (level == 10) unlockedTraits[tokenId][3] = 13;
      else if (level == 11) unlockedTraits[tokenId][4] = 5;
      else if (level == 12) unlockedTraits[tokenId][2] = 15;
      else if (level == 13) unlockedTraits[tokenId][3] = 17;
      else if (level == 14) unlockedTraits[tokenId][4] = 6;
      else if (level == 15) unlockedTraits[tokenId][3] = 19;
      else if (level == 16) unlockedTraits[tokenId][0] = 12;
      else if (level == 17) unlockedTraits[tokenId][1] = 11;
      else if (level == 18) unlockedTraits[tokenId][2] = 18;
      else if (level == 19) unlockedTraits[tokenId][3] = 22;
      else if (level == 20) unlockedTraits[tokenId][4] = 7;
      else if (level == 21) unlockedTraits[tokenId][5] = 5;
      else if (level == 22) unlockedTraits[tokenId][0] = 14;
      else if (level == 23) unlockedTraits[tokenId][1] = 12;
      else if (level == 24) unlockedTraits[tokenId][3] = 24;
      else if (level == 25) unlockedTraits[tokenId][4] = 8;
      else if (level == 26) unlockedTraits[tokenId][5] = 7;
      else if (level == 27) unlockedTraits[tokenId][0] = 15;
      else if (level == 28) unlockedTraits[tokenId][1] = 13;
      else if (level == 29) unlockedTraits[tokenId][4] = 9;
      else if (level == 30) unlockedTraits[tokenId][2] = 20;
      else if (level == 31) unlockedTraits[tokenId][0] = 16;
      else if (level == 32) unlockedTraits[tokenId][1] = 14;
      else if (level == 33) unlockedTraits[tokenId][2] = 21;
      else if (level == 34) unlockedTraits[tokenId][3] = 25;
      else if (level == 35) unlockedTraits[tokenId][4] = 10;
      else if (level == 36) unlockedTraits[tokenId][5] = 8;
      else if (level == 37) unlockedTraits[tokenId][0] = 17;
      else if (level == 38) unlockedTraits[tokenId][1] = 15;
      else if (level == 39) unlockedTraits[tokenId][2] = 23;
      else if (level == 40) unlockedTraits[tokenId][3] = 26;
      else if (level == 41) unlockedTraits[tokenId][4] = 11;
      else if (level == 42) unlockedTraits[tokenId][5] = 42;
      else if (level == 43) unlockedTraits[tokenId][0] = 18;
      else if (level == 44) unlockedTraits[tokenId][1] = 16;
      else if (level == 45) unlockedTraits[tokenId][2] = 24;
      else if (level == 46) unlockedTraits[tokenId][3] = 27;
      else if (level == 47) unlockedTraits[tokenId][4] = 12;
      else if (level == 48) unlockedTraits[tokenId][0] = 20;
      else if (level == 49) unlockedTraits[tokenId][2] = 25;
      else if (level == 50) unlockedTraits[tokenId][3] = 28;
    }
  }

  function isUnlocked(
    uint256 tokenId,
    uint256 traitType,
    uint256 traitId
  ) public returns (bool) {
    if (peekaboo.getTokenTraits(tokenId).isGhost) {
      if (
        (traitType == 0 && traitId <= 6) ||
        (traitType == 1 && traitId <= 8) ||
        (traitType == 2 && traitId <= 7) ||
        (traitType == 3 && traitId <= 13) ||
        (traitType == 4 && traitId <= 12) ||
        (traitType == 5 && traitId <= 6) ||
        (traitType == 6 && traitId <= 6)
      ) {
        return true;
      }
    } else {
      if (
        (traitType == 0 && traitId <= 6) ||
        (traitType == 1 && traitId <= 4) ||
        (traitType == 2 && traitId <= 11) ||
        (traitType == 3 && traitId <= 9) ||
        (traitType == 4 && traitId <= 3) ||
        (traitType == 5 && traitId <= 1)
      ) {
        return true;
      }
    }
    return (traitId <= unlockedTraits[tokenId][traitType]);
  }

  function setGrowthRate(uint256 rate) external onlyOwner {
    require(rate > 10, "No declining rate.");
    EXP_GROWTH_RATE1 = rate;
  }

  function setEXPDifficulty(
    uint256 easy,
    uint256 medium,
    uint256 hard
  ) public onlyOwner {
    difficultyToEXP[0] = easy;
    difficultyToEXP[1] = medium;
    difficultyToEXP[2] = hard;
  }

  function setStakeManager(address _stakeManager) public onlyOwner {
    stakeManager = StakeManager(_stakeManager);
  }

  function setPeekABoo(address _peekaboo) external onlyOwner {
    peekaboo = PeekABoo(_peekaboo);
  }

  function getUnlockedTraits(uint256 tokenId, uint256 traitType) public returns (uint256) {
    return unlockedTraits[tokenId][traitType];
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "../.deps/npm/@openzeppelin/contracts/security/Pausable.sol";
import "../.deps/npm/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PeekABoo.sol";
import "./Traits.sol";
import "./Level.sol";

contract InGame is Ownable, Pausable {
  // tokenId => traitType => traitId => bool
  mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) public boughtTraits;
  mapping(uint256 => bool[6]) public boughtAbilities;
  // tokenId => boughtTraitCountByRarity [common,uncommon,...]
  mapping(uint256 => uint256[4]) public boughtTraitCount;

  PeekABoo public peekaboo;
  Traits public traits;
  Level public level;
  IERC20 public boo;
  IERC20 public magic;
  uint256 public traitPriceRate;
  uint256 public abilityPriceRate;

  constructor(
    PeekABoo _peekaboo,
    Traits _traits,
    Level _level,
    address _boo,
    address _magic
  ) {
    peekaboo = _peekaboo;
    traits = _traits;
    level = _level;
    boo = IERC20(_boo);
    magic = IERC20(_magic);
    traitPriceRate = 12 ether;
    abilityPriceRate = 30 ether;
  }

  modifier onlyPeekABoo {
    require(_msgSender() == address(peekaboo), "Must be PeekABoo.sol, don't cheat");
    _;
  }

  function buyTraits(
    uint256 tokenId,
    uint256[] calldata traitTypes,
    uint256[] calldata traitIds,
    uint256 amount
  ) external {
    require(_msgSender() == peekaboo.getTokenTraits(tokenId).owner, "Traits can only be purchased by owner");
    require(traitTypes.length == traitIds.length, "traitTypes and traitIds lengths are different");
    uint256 totalBOO = 0;
    bool _isGhost = peekaboo.getTokenTraits(tokenId).isGhost;
    if (_isGhost == true) {
      for (uint256 i = 0; i < traitIds.length; i++) {
        require(traitIds[i] <= level.getUnlockedTraits(tokenId, traitTypes[i]), "Trait not unlocked yet");
        if (traitIds[i] <= traits.getRarityIndex(0, traitTypes[i], 1)) {
          totalBOO += traitPriceRate;
          boughtTraitCount[tokenId][1] = boughtTraitCount[tokenId][1] + 1;
        } else if (traitIds[i] <= traits.getRarityIndex(0, traitTypes[i], 2)) {
          totalBOO += (traitPriceRate * 2);
          boughtTraitCount[tokenId][2] = boughtTraitCount[tokenId][2] + 1;
        } else if (traitIds[i] <= traits.getRarityIndex(0, traitTypes[i], 3)) {
          totalBOO += (traitPriceRate * 3);
          boughtTraitCount[tokenId][3] = boughtTraitCount[tokenId][3] + 1;
        }
        boughtTraits[tokenId][traitTypes[i]][traitIds[i]] = true;
      }
    } else {
      for (uint256 i = 0; i < traitIds.length; i++) {
        require(traitIds[i] <= level.getUnlockedTraits(tokenId, traitTypes[i]), "Trait not unlocked yet");
        if (traitIds[i] <= traits.getRarityIndex(1, traitTypes[i], 1)) {
          totalBOO += traitPriceRate;
          boughtTraitCount[tokenId][1] = boughtTraitCount[tokenId][1] + 1;
        } else if (traitIds[i] <= traits.getRarityIndex(1, traitTypes[i], 2)) {
          totalBOO += (traitPriceRate * 2);
          boughtTraitCount[tokenId][2] = boughtTraitCount[tokenId][2] + 1;
        } else if (traitIds[i] <= traits.getRarityIndex(1, traitTypes[i], 3)) {
          totalBOO += (traitPriceRate * 3);
          boughtTraitCount[tokenId][3] = boughtTraitCount[tokenId][3] + 1;
        }
        boughtTraits[tokenId][traitTypes[i]][traitIds[i]] = true;
      }
    }
    require(amount >= totalBOO, "Not enough $BOO");
    _approveFor(msg.sender, boo, amount);
    boo.transferFrom(msg.sender, address(this), amount);
  }

  function buyAbilities(
    uint256 tokenId,
    uint256[] calldata abilities,
    uint256 amount
  ) external {
    require(_msgSender() == peekaboo.getTokenTraits(tokenId).owner, "Only owner can buy abilities");
    uint256 totalMAGIC = 0;
    uint256 _tier = peekaboo.getTokenTraits(tokenId).tier;
    require(peekaboo.getTokenTraits(tokenId).isGhost == false, "Only busters can buy abilities");
    for (uint256 i = 0; i < abilities.length; i++) {
      if (abilities[i] == 0) {
        require(_tier >= 1, "This ability cannot be bought yet at this tier");
        if (_tier < 2) require(boughtAbilities[tokenId][1] == false, "This ability cannot be bought yet at this tier");
        totalMAGIC += abilityPriceRate;
        boughtAbilities[tokenId][0] = true;
      } else if (abilities[i] == 1) {
        require(_tier >= 1, "This ability cannot be bought yet at this tier");
        if (_tier < 2) require(boughtAbilities[tokenId][0] == false, "This ability cannot be bought yet at this level");
        totalMAGIC += abilityPriceRate;
        boughtAbilities[tokenId][1] = true;
      } else if (abilities[i] == 2) {
        require(_tier >= 3, "This ability cannot be bought yet at this tier");
        if (_tier == 3)
          require(
            boughtAbilities[tokenId][3] == false && boughtAbilities[tokenId][4] == false,
            "This ability cannot be bought yet at this level"
          );
        if (_tier == 4)
          require(
            boughtAbilities[tokenId][3] == false || boughtAbilities[tokenId][4] == false,
            "This ability cannot be bought yet at this level"
          );
        totalMAGIC += abilityPriceRate * 2;
        boughtAbilities[tokenId][2] = true;
      } else if (abilities[i] == 3) {
        require(_tier >= 3, "This ability cannot be bought yet at this tier");
        if (_tier == 3)
          require(
            boughtAbilities[tokenId][2] == false && boughtAbilities[tokenId][4] == false,
            "This ability cannot be bought yet at this level"
          );
        if (_tier == 4)
          require(
            boughtAbilities[tokenId][2] == false || boughtAbilities[tokenId][4] == false,
            "This ability cannot be bought yet at this level"
          );
        totalMAGIC += abilityPriceRate * 2;
        boughtAbilities[tokenId][3] = true;
      } else if (abilities[i] == 4) {
        require(_tier >= 3, "This ability cannot be bought yet at this tier");
        if (_tier == 3)
          require(
            boughtAbilities[tokenId][2] == false && boughtAbilities[tokenId][4] == false,
            "This ability cannot be bought yet at this level"
          );
        if (_tier == 4)
          require(
            boughtAbilities[tokenId][2] == false || boughtAbilities[tokenId][4] == false,
            "This ability cannot be bought yet at this level"
          );
        totalMAGIC += abilityPriceRate * 2;
        boughtAbilities[tokenId][4] = true;
      } else if (abilities[i] == 5) {
        require(_tier >= 5, "This ability cannot be bought yet at this tier");
        totalMAGIC += abilityPriceRate * 3;
        boughtAbilities[tokenId][5] = true;
      }
    }
    require(amount >= totalMAGIC, "Not enough $MAGIC");
    _approveFor(msg.sender, magic, amount);
    magic.transferFrom(msg.sender, address(this), amount);
  }

  function tierUp(uint256 tokenId, uint64 toTier) external {
    require(_msgSender() == peekaboo.getTokenTraits(tokenId).owner, "Only owner can tier up the token");
    if (peekaboo.getTokenTraits(tokenId).tier == 0) {
      require(peekaboo.getTokenTraits(tokenId).level / 10 >= 1, "You cannot reach this tier yet");
      if (peekaboo.getTokenTraits(tokenId).isGhost == true) {
        require(boughtTraitCount[tokenId][1] >= 7, "Not enough uncommon traits bought");
      } else require(boughtTraitCount[tokenId][1] >= 6, "Not enough uncommon traits bought");
    } else if (peekaboo.getTokenTraits(tokenId).tier == 1) {
      require(peekaboo.getTokenTraits(tokenId).level / 10 >= 2, "You cannot reach this tier yet");
      if (peekaboo.getTokenTraits(tokenId).isGhost == true) {
        require(boughtTraitCount[tokenId][1] >= 14, "Not enough uncommon traits bought");
      } else require(boughtTraitCount[tokenId][1] >= 12, "Not enough uncommon traits bought");
    } else if (peekaboo.getTokenTraits(tokenId).tier == 2) {
      require(peekaboo.getTokenTraits(tokenId).level / 10 >= 3, "You cannot reach this tier yet");
      if (peekaboo.getTokenTraits(tokenId).isGhost == true) {
        require(boughtTraitCount[tokenId][2] >= 7, "Not enough rare traits bought");
      } else require(boughtTraitCount[tokenId][2] >= 6, "Not enough rare traits bought");
    } else if (peekaboo.getTokenTraits(tokenId).tier == 3) {
      require(peekaboo.getTokenTraits(tokenId).level / 10 >= 4, "You cannot reach this tier yet");
      if (peekaboo.getTokenTraits(tokenId).isGhost == true) {
        require(boughtTraitCount[tokenId][2] >= 7, "Not enough legendary traits bought");
      } else require(boughtTraitCount[tokenId][2] >= 6, "Not enough legendary traits bought");
    } else if (peekaboo.getTokenTraits(tokenId).tier == 4) {
      require(peekaboo.getTokenTraits(tokenId).level / 10 >= 5, "You cannot reach this tier yet");
      uint256 _boughtTraits = boughtTraitCount[tokenId][1] +
        boughtTraitCount[tokenId][2] +
        boughtTraitCount[tokenId][2];
      if (peekaboo.getTokenTraits(tokenId).isGhost == true) {
        require(_boughtTraits >= 127, "Not enough traits bought");
      } else require(_boughtTraits >= 76, "Not enough traits bought");
    } else {
      return;
    }
    peekaboo.incrementTier(tokenId);
  }

  function getBoughtTraitCount(uint256 tokenId, uint256 rarity) external returns (uint256) {
    return boughtTraitCount[tokenId][rarity];
  }

  function isBoughtTrait(
    uint256 tokenId,
    uint256 traitType,
    uint256 traitId
  ) external returns (bool) {
    uint256 ghostOrBuster = (peekaboo.getTokenTraits(tokenId).isGhost == true) ? 0 : 1;
    uint256 commonIndex = traits.getRarityIndex(ghostOrBuster, traitType, 0);
    if (traitId <= commonIndex) return true;
    return boughtTraits[tokenId][traitType][traitId];
  }

  function isBoughtAbility(uint256 tokenId, uint256 ability) external returns (bool) {
    return boughtAbilities[tokenId][ability];
  }

  function _approveFor(
    address owner,
    IERC20 token,
    uint256 amount
  ) internal {
    token.approve(address(this), amount);
  }

  function setBOO(address _boo) external onlyOwner {
    boo = IERC20(_boo);
  }

  function setMagic(address _magic) external onlyOwner {
    magic = IERC20(_magic);
  }

  function setPeekABoo(address _pab) external onlyOwner {
    peekaboo = PeekABoo(_pab);
  }

  function setTraits(address _traits) external onlyOwner {
    traits = Traits(_traits);
  }

  function setLevel(address _level) external onlyOwner {
    level = Level(_level);
  }

  function setTraitPriceRate(uint256 rate) external onlyOwner {
    traitPriceRate = rate;
  }

  function setAbilityPriceRate(uint256 rate) external onlyOwner {
    abilityPriceRate = rate;
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;

interface IPeekABoo {
  struct PeekABooTraits {
    bool isGhost;
    uint256 background;
    uint256 back;
    uint256 bodyColor;
    uint256 hat;
    uint256 face;
    uint256 clothesOrHelmet;
    uint256 hands;
    uint64 ability;
    uint64 revealShape;
    uint64 tier;
    uint64 level;
    address owner;
    bool[5] phase2Minted;
  }

  struct GhostMap {
    uint256[10][10] grid;
    int256 gridSize;
    uint256 difficulty;
    bool initialized;
  }

  function getTokenTraits(uint256 tokenId)
    external
    view
    returns (PeekABooTraits memory);

  function setTokenTraits(
    uint256 tokenId,
    uint256 traitType,
    uint256 traitId
  ) external;

  function setMultipleTokenTraits(
    uint256 tokenId,
    uint256[] calldata traitTypes,
    uint256[] calldata traitIds
  ) external;

  function getGhostMapGridFromTokenId(uint256 tokenId)
    external
    view
    returns (GhostMap memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;

interface IHideNSeek {
  struct GhostMapSession {
    bool active;
    uint256 sessionId;
    uint256 difficulty;
    uint256 cost;
    uint256 balance;
    bytes32 commitment;
    address owner;
    address busterPlayer;
    uint256 numberOfBusters;
    uint256[3] busterTokenIds;
    int256[2][3] busterPositions;
  }

  struct Session {
    uint256 tokenId;
    uint256 sessionId;
    address lockedBy;
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;

import "./PeekABoo.sol";
import "./IPeekABoo.sol";
import "./IHideNSeek.sol";
import "./BOO.sol";
import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";

contract HideNSeekGameLogic is IHideNSeek, Ownable {
    // reference to the peekaboo smart contract
    PeekABoo public peekaboo;
    BOO public boo;

    event Game(uint256 session, address indexed ghostPlayer, address indexed busterPlayer, bool ghostWon, uint256 indexed ghostId);
    event SessionBuster(uint256 indexed session, address indexed busterPlayer, uint256 indexed ghostId, uint256[] busterIds, int256[2][] busterPositions);

    mapping (uint256 => mapping (uint256 => GhostMapSession)) public TIDtoGhostMapSession;
    mapping (uint256 => uint256) public TIDtoNextSessionNumber;
    mapping (uint256 => uint256[]) public TIDtoActiveSessions;
    mapping (address => Session[]) public claimableSessions;
    mapping (address => Session) lockedSessions;
    Session[] activeSessions;

    function playGame(uint256[] calldata busterIds, int256[2][] calldata busterPos, uint256 tokenId, uint256 sessionId, uint256 cost) internal {
        PeekABoo peekabooRef = peekaboo;

        boo.transferFrom(_msgSender(), address(this), cost);
        TIDtoGhostMapSession[tokenId][sessionId].balance += cost;
        TIDtoGhostMapSession[tokenId][sessionId].busterPlayer = _msgSender();
        TIDtoGhostMapSession[tokenId][sessionId].numberOfBusters = busterIds.length;
        for (uint256 i=0; i<busterIds.length; i++) {
            TIDtoGhostMapSession[tokenId][sessionId].busterTokenIds[i] = busterIds[i];
            TIDtoGhostMapSession[tokenId][sessionId].busterPositions[i] = busterPos[i];
        }
    }

    // Returns true if ghost wins, false if ghost loses
    function verifyGame(GhostMapSession memory gms, uint256 tokenId, int256[2] calldata ghostPosition, uint256 nonce, uint256 sessionId) internal returns (bool) {
        // PeekABoo peekabooRef = peekaboo;
        BOO booRef = boo;

        for (uint i = 0; i < gms.numberOfBusters; i++)
        {
            // Ghost reveal logic
            if (doesRadiusReveal(gms.busterPositions[i], peekaboo.getTokenTraits(gms.busterTokenIds[i]).revealShape, gms.busterTokenIds[i], ghostPosition)||
                (gms.busterTokenIds.length == 1
                    ? doesAbilityReveal(gms.busterPositions[i], gms.busterTokenIds[i], ghostPosition)
                    : (gms.busterTokenIds.length == 2
                        ? doesAbilityReveal(gms.busterPositions[i], gms.busterTokenIds[i], ghostPosition, gms.busterPositions[(i == 0) ? 1 : 0])
                        : doesAbilityReveal(gms.busterPositions[i], gms.busterTokenIds[i], ghostPosition, gms.busterPositions[(i == 0) ? 2 : 0], gms.busterPositions[(i == 1) ? 2 : 1])))
                )
            {   
                //Boo Generator Cashing
                // if (peekabooRef.getTokenTraits(gms.busterTokenIds[i]).ability == 6) {
                //     booRef.mint(gms.busterPlayer, 10 ether);
                // }

                return true;
            }
        }
        return false;
    }

    function doesRadiusReveal(int256[2] memory busterPosition, uint256 revealShape, uint256 busterId, int256[2] memory ghostPosition) internal view returns (bool) {
        // NormalRevealShape
        if (revealShape == 0) {
            for(int256 i = -1; i <= 1; i++) {
                for(int256 j = -1; j <= 1; j++) {
                    if ((ghostPosition[0] == busterPosition[0] + i && ghostPosition[1] == busterPosition[1] + j))
                        return true;
                }
            }
        }

        // PlusRevealShape
        else if (revealShape == 1) {
            for(int256 i = -2; i <= 2; i++) {
                if (ghostPosition[0] == busterPosition[0] && ghostPosition[1] == busterPosition[1] + i ||
                    ghostPosition[0] == busterPosition[0] + i && ghostPosition[1] == busterPosition[1])
                        return true;
            }
        }
    
        // XRevealShape
        else if (revealShape == 2) {
            for(int256 i = -2; i <= 2; i++) {
                if (ghostPosition[0] == busterPosition[0] + i && ghostPosition[1] == busterPosition[1] + i) {
                    return true;
                }
            }
        }
        
        return false;
    }

    function doesAbilityReveal(int256[2] memory busterPosition, uint256 busterId, int256[2] memory ghostPosition, int256[2] memory otherBuster1, int256[2] memory otherBuster2) internal view returns (bool) {
        PeekABoo peekabooRef = peekaboo;
        //LightBuster
        if (peekabooRef.getTokenTraits(busterId).ability == 1) {
            if (ghostPosition[0] == busterPosition[0])
                return true;
        }

        //HomeBound
        else if (peekabooRef.getTokenTraits(busterId).ability == 2) {
            if  (((busterPosition[0] == otherBuster1[0]) && (busterPosition[0] == ghostPosition[0])) || // Buster 1 on same row
                ((busterPosition[0] == otherBuster2[0]) && (busterPosition[0] == ghostPosition[0]))  || // Buster 2 on same row
                ((busterPosition[1] == otherBuster1[1]) && (busterPosition[1] == ghostPosition[1]))  || // Buster 1 on same column
                ((busterPosition[1] == otherBuster2[1]) && (busterPosition[1] == ghostPosition[1])))    // Buster 2 on same column
            {
                return true;
            }
        }

        //GreenGoo
        else if (peekabooRef.getTokenTraits(busterId).ability == 3) {
            if (ghostPosition[1] == busterPosition[1]) {
                return true;
            }
        }

        //StandUnited 
        else if (peekabooRef.getTokenTraits(busterId).ability == 4) {
            if (isBusterAdjacent(busterPosition, otherBuster1) || 
                isBusterAdjacent(busterPosition, otherBuster2))
            {
                for(int256 i = -2; i <= 2; i++) {
                    for(int256 j = -2; i <= 2; i++) {
                        if ((ghostPosition[0] == busterPosition[0] + i && ghostPosition[1] == busterPosition[1] + j))
                            return true;
                    }
                }
            }
        }

        //HolyCross
        else if (peekabooRef.getTokenTraits(busterId).ability == 5) {
            if (ghostPosition[0] == busterPosition[0] || ghostPosition[1] == busterPosition[1]) {
                return true;
            }
        }

        return false;
    }

    function doesAbilityReveal(int256[2] memory busterPosition, uint256 busterId, int256[2] memory ghostPosition, int256[2] memory otherBuster1) internal view returns (bool) {
        PeekABoo peekabooRef = peekaboo;
        //LightBuster
        if (peekabooRef.getTokenTraits(busterId).ability == 1) {
            if (ghostPosition[0] == busterPosition[0])
                return true;
        }

        //HomeBound
        else if (peekabooRef.getTokenTraits(busterId).ability == 2) {
            if  (((busterPosition[0] == otherBuster1[0]) && (busterPosition[0] == ghostPosition[0])) || // Buster 1 on same row
                ((busterPosition[1] == otherBuster1[1]) && (busterPosition[1] == ghostPosition[1]))) // Buster 1 on same column
            {
                return true;
            }
        }

        //GreenGoo
        else if (peekabooRef.getTokenTraits(busterId).ability == 3) {
            if (ghostPosition[1] == busterPosition[1]) {
                return true;
            }
        }

        //StandUnited 
        else if (peekabooRef.getTokenTraits(busterId).ability == 4) {
            if (isBusterAdjacent(busterPosition, otherBuster1))
            {
                for(int256 i = -2; i <= 2; i++) {
                    for(int256 j = -2; i <= 2; i++) {
                        if ((ghostPosition[0] == busterPosition[0] + i && ghostPosition[1] == busterPosition[1] + j))
                            return true;
                    }
                }
            }
        }

        //HolyCross
        else if (peekabooRef.getTokenTraits(busterId).ability == 5) {
            if (ghostPosition[0] == busterPosition[0] || ghostPosition[1] == busterPosition[1]) {
                return true;
            }
        }

        return false;
    }

    function doesAbilityReveal(int256[2] memory busterPosition, uint256 busterId, int256[2] memory ghostPosition) internal view returns (bool) {
        PeekABoo peekabooRef = peekaboo;
        //LightBuster
        if (peekabooRef.getTokenTraits(busterId).ability == 1) {
            if (ghostPosition[0] == busterPosition[0])
                return true;
        }

        //GreenGoo
        else if (peekabooRef.getTokenTraits(busterId).ability == 3) {
            if (ghostPosition[1] == busterPosition[1]) {
                return true;
            }
        }

        //HolyCross
        else if (peekabooRef.getTokenTraits(busterId).ability == 5) {
            if (ghostPosition[0] == busterPosition[0] || ghostPosition[1] == busterPosition[1]) {
                return true;
            }
        }

        return false;
    }

    function isBusterAdjacent(int256[2] memory pos1, int256[2] memory pos2) internal pure returns (bool)
    {
        int256 difference = pos1[0] + pos1[1] - (pos2[0] + pos2[1]);
        return difference <= 1 && difference >= -1; 
    }

    function verifyCommitment(uint256 tokenId, uint256 sessionId, int256[2] calldata ghostPosition, uint256 nonce) internal view returns (bool) {
        return bytes32(keccak256(abi.encodePacked(tokenId,
            ghostPosition[0],
            ghostPosition[1],
            nonce
        ))) == TIDtoGhostMapSession[tokenId][sessionId].commitment;
    }

    function hasEnoughBooToFund(uint256[] calldata booFundingAmount, address sender) internal view returns (bool){
        uint256 totalBooFundingAmount;
        for (uint256 i = 0; i< booFundingAmount.length; i++) {
            totalBooFundingAmount += booFundingAmount[i];
        }
        return boo.balanceOf(sender) >= totalBooFundingAmount;
    }

    function isNotInBound(uint256 tokenId, int256[2] calldata position) internal view returns (bool) {
        IPeekABoo.GhostMap memory ghostMap = peekaboo.getGhostMapGridFromTokenId(tokenId);
        if (ghostMap.grid[uint256(position[1])][uint256(position[0])] == 1
            || position[0] < 0
            || position[0] > ghostMap.gridSize - 1
            || position[1] < 0
            || position[1] > ghostMap.gridSize - 1) {
            return true;
        }
        return false;
    }

    function removeActiveGhostMap(uint256 tokenId, uint256 sessionId) internal {
        for (uint i=0; i<activeSessions.length; i++) {
            if (activeSessions[i].tokenId == tokenId && activeSessions[i].sessionId == sessionId) {
                activeSessions[i] = activeSessions[activeSessions.length - 1];
                activeSessions.pop();
                break;
            }
        }
        for (uint i=0; i<TIDtoActiveSessions[tokenId].length; i++) {
            if (TIDtoActiveSessions[tokenId][i] == sessionId) {
                TIDtoActiveSessions[tokenId][i] = TIDtoActiveSessions[tokenId][TIDtoActiveSessions[tokenId].length - 1];
                TIDtoActiveSessions[tokenId].pop();
                return;
            }
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;

import "./HideNSeekGameLogic.sol";
import "./StakeManager.sol";
import "./Level.sol";

contract HideNSeek is HideNSeekGameLogic {
  event StakedPeekABoo(address from, uint256 tokenId);
  event UnstakedPeekABoo(address from, uint256 tokenId);
  event ClaimedGhostMap(uint256 tokenId, uint256 sessionId);
  event PlayedGame(address from, uint256 tokenId, uint256 sessionId);
  event GhostMapCreated(address indexed ghostPlayer, uint256 indexed tokenId, uint256 session);
  event GameComplete(
    address winner,
    address loser,
    uint256 indexed tokenId,
    uint256 indexed session,
    uint256 difficulty,
    uint256 winnerAmount,
    uint256 loserAmount
  );

  uint256[3] public GHOST_COSTS;
  uint256[3] public BUSTER_COSTS;
  uint256[2] public BUSTER_BONUS;

  uint256 TAX;

  constructor(
    uint256[3] memory _GHOST_COSTS,
    uint256[3] memory _BUSTER_COSTS,
    uint256[2] memory _BUSTER_BONUS
  ) {
    GHOST_COSTS = _GHOST_COSTS;
    BUSTER_COSTS = _BUSTER_COSTS;
    BUSTER_BONUS = _BUSTER_BONUS;
  }

  address ACS;

  StakeManager sm;
  Level level;

  function stakePeekABoo(uint256[] calldata tokenIds) external {
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(peekabooRef.ownerOf(tokenIds[i]) == _msgSender(), "This isn't your token");
      smRef.stakePABOnService(tokenIds[i], address(this), _msgSender());
      emit StakedPeekABoo(_msgSender(), tokenIds[i]);
    }
  }

  function unstakePeekABoo(uint256[] calldata tokenIds) external {
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(smRef.isStaked(tokenIds[i], address(this), _msgSender()), "Not staked.");
      require(
        smRef.tokenIdToOwner(tokenIds[i]) == _msgSender() && peekabooRef.ownerOf(tokenIds[i]) == _msgSender(),
        "Not your token."
      );
      smRef.unstakePeekABoo(tokenIds[i]);
      emit UnstakedPeekABoo(_msgSender(), tokenIds[i]);
      if (peekabooRef.getTokenTraits(tokenIds[i]).isGhost) {
        for (uint256 j = 0; j < TIDtoActiveSessions[tokenIds[i]].length; j++) {
          removeActiveGhostMap(tokenIds[i], TIDtoActiveSessions[tokenIds[i]][j]);
        }
      }
    }
  }

  function createGhostMaps(uint256 tokenId, bytes32[] calldata commitments)
    external
    returns (uint256[2] memory sessionsFrom)
  {
    BOO booRef = boo;
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;

    require(tx.origin == msg.sender, "No SmartContracts");
    require(smRef.isStaked(tokenId, address(this), msg.sender), "This is not staked in HideNSeek");
    require(peekabooRef.getTokenTraits(tokenId).isGhost, "Not a ghost, can't create GhostMaps");
    require(smRef.tokenIdToOwner(tokenId) == msg.sender, "This isn't your token");
    require(peekabooRef.getGhostMapGridFromTokenId(tokenId).initialized, "Ghostmap is not initialized");

    smRef.claimEnergy(tokenId);
    smRef.useEnergy(tokenId, commitments.length);

    uint256 cost = GHOST_COSTS[peekabooRef.getGhostMapGridFromTokenId(tokenId).difficulty];
    uint256 total = cost * commitments.length;
    uint256 sessionId;
    sessionsFrom[1] = commitments.length;
    for (uint256 i = 0; i < commitments.length; i++) {
      sessionId = TIDtoNextSessionNumber[tokenId];
      if (i == 0) {
        sessionsFrom[0] = sessionId;
      }
      TIDtoGhostMapSession[tokenId][sessionId].active = true;
      TIDtoGhostMapSession[tokenId][sessionId].sessionId = sessionId;
      TIDtoGhostMapSession[tokenId][sessionId].difficulty = peekabooRef.getGhostMapGridFromTokenId(tokenId).difficulty;
      TIDtoGhostMapSession[tokenId][sessionId].cost = cost;
      TIDtoGhostMapSession[tokenId][sessionId].balance = cost;
      TIDtoGhostMapSession[tokenId][sessionId].commitment = commitments[i];
      TIDtoGhostMapSession[tokenId][sessionId].owner = _msgSender();
      TIDtoNextSessionNumber[tokenId] = sessionId + 1;
      TIDtoActiveSessions[tokenId].push(sessionId);
      activeSessions.push(Session(tokenId, sessionId, address(0x0)));
      emit GhostMapCreated(msg.sender, tokenId, sessionId);
    }
    booRef.transferFrom(msg.sender, address(this), total);
  }

  function claimGhostMaps(
    uint256 tokenId,
    uint256[] calldata sessionIds,
    int256[2][] calldata ghostPositions,
    uint256[] calldata nonces
  ) external {
    require(sessionIds.length == nonces.length, "Incorrect lengths for ghostPositions");
    require(sessionIds.length == ghostPositions.length, "Incorrect lengths for nonces");
    if (_msgSender() != ACS)
      require(sm.isStaked(tokenId, address(this), _msgSender()), "This is not staked in HideNSeek");

    for (uint256 i = 0; i < sessionIds.length; i++) {
      claimGhostMap(tokenId, sessionIds[i], ghostPositions[i], nonces[i]);
      emit ClaimedGhostMap(tokenId, sessionIds[i]);
    }
  }

  function generateLockedSession() external {
    require(lockedSessions[_msgSender()].lockedBy == address(0x0), "You already have a locked session");
    uint256 index = pseudoRandom(_msgSender()) % activeSessions.length;
    activeSessions[index].lockedBy = _msgSender();
    Session memory session = activeSessions[index];

    lockedSessions[_msgSender()] = session;
    removeActiveGhostMap(session.tokenId, session.sessionId);
  }

  function playGameSession(uint256[] calldata busterIds, int256[2][] calldata busterPos) external {
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;
    require(lockedSessions[_msgSender()].lockedBy != address(0x0), "You have not locked in a session yet");
    uint256 tokenId = lockedSessions[_msgSender()].tokenId;
    uint256 sessionId = lockedSessions[_msgSender()].sessionId;
    GhostMapSession memory gms = TIDtoGhostMapSession[tokenId][sessionId];

    for (uint256 i = 0; i < busterIds.length; i++) {
      smRef.claimEnergy(busterIds[i]);
      smRef.useEnergy(busterIds[i], 1);
    }

    require(tx.origin == _msgSender(), "No SmartContracts");
    require(busterIds.length == busterPos.length, "Incorrect lengths");
    require(busterIds.length <= 3, "Can only play with up to 3 busters");
    require(peekabooRef.ownerOf(busterIds[0]) == _msgSender(), "You don't own this buster.");
    require(!peekabooRef.getTokenTraits(busterIds[0]).isGhost, "You can't play with a ghost");
    if (busterIds.length == 2) {
      require(peekabooRef.ownerOf(busterIds[1]) == _msgSender(), "You don't own this buster.");
      require(!peekabooRef.getTokenTraits(busterIds[1]).isGhost, "You can't play with a ghost");
    } else if (busterIds.length == 3) {
      require(peekabooRef.ownerOf(busterIds[1]) == _msgSender(), "You don't own this buster.");
      require(peekabooRef.ownerOf(busterIds[2]) == _msgSender(), "You don't own this buster.");
      require(!peekabooRef.getTokenTraits(busterIds[1]).isGhost, "You can't play with a ghost");
      require(!peekabooRef.getTokenTraits(busterIds[2]).isGhost, "You can't play with a ghost");
    }
    require(gms.owner != _msgSender(), "Cannot Play your own map.");
    require(!isNotInBound(tokenId, busterPos[0]), "buster1 not inbound");
    if (busterIds.length == 2) {
      require(
        !(busterPos[0][0] == busterPos[1][0] && busterPos[0][1] == busterPos[1][1]),
        "buster1 pos cannot be same as buster2"
      );
      require(!isNotInBound(tokenId, busterPos[1]), "buster2 not inbound");
    } else if (busterIds.length == 3) {
      require(
        !(busterPos[0][0] == busterPos[1][0] && busterPos[0][1] == busterPos[1][1]),
        "buster1 pos cannot be same as buster2"
      );
      require(
        !(busterPos[0][0] == busterPos[2][0] && busterPos[0][1] == busterPos[2][1]),
        "buster1 pos cannot be same as buster3"
      );
      require(
        !(busterPos[1][0] == busterPos[2][0] && busterPos[1][1] == busterPos[2][1]),
        "buster2 pos cannot be same as buster3"
      );
      require(!isNotInBound(tokenId, busterPos[1]), "buster2 not inbound");
      require(!isNotInBound(tokenId, busterPos[2]), "buster3 not inbound");
    }

    playGame(busterIds, busterPos, tokenId, sessionId, BUSTER_COSTS[gms.difficulty]);
    emit PlayedGame(_msgSender(), tokenId, sessionId);
    claimableSessions[gms.owner].push(lockedSessions[_msgSender()]);
    delete lockedSessions[_msgSender()];
  }

  //Admin Access
  function setPeekABoo(address _peekaboo) external onlyOwner {
    peekaboo = PeekABoo(_peekaboo);
  }

  function setBOO(address _boo) external onlyOwner {
    boo = BOO(_boo);
  }

  function setStakeManager(address _sm) external onlyOwner {
    sm = StakeManager(_sm);
  }

  function setLevel(address _level) external onlyOwner {
    level = Level(_level);
  }

  // Internal
  function claimGhostMap(
    uint256 tokenId,
    uint256 sessionId,
    int256[2] calldata ghostPosition,
    uint256 nonce
  ) internal {
    BOO booRef = boo;
    PeekABoo peekabooRef = peekaboo;
    StakeManager smRef = sm;
    address ghostOwner = smRef.tokenIdToOwner(tokenId);
    require(verifyCommitment(tokenId, sessionId, ghostPosition, nonce), "Commitment incorrect, please do not cheat");

    GhostMapSession memory gms = TIDtoGhostMapSession[tokenId][sessionId];

    if (isNotInBound(tokenId, ghostPosition)) {
      booRef.transfer(gms.busterPlayer, gms.balance);
      TIDtoGhostMapSession[tokenId][sessionId].balance = 0;
      return;
    }

    uint256 ghostReceive;
    uint256 busterReceive;
    uint256 difficulty = gms.difficulty;
    if (verifyGame(gms, tokenId, ghostPosition, nonce, sessionId)) {
      if (gms.numberOfBusters == 1) {
        ghostReceive = 0 * 1 ether;
        busterReceive = gms.balance - ghostReceive;
        booRef.transfer(gms.busterPlayer, busterReceive);
        booRef.mint(gms.busterPlayer, BUSTER_BONUS[1]);
      } else if (gms.numberOfBusters == 2) {
        ghostReceive = 5 * 1 ether;
        busterReceive = gms.balance - ghostReceive;
        booRef.transfer(ghostOwner, ghostReceive);
        booRef.transfer(gms.busterPlayer, busterReceive);
        booRef.mint(gms.busterPlayer, BUSTER_BONUS[0]);
      } else {
        ghostReceive = 10 * 1 ether;
        busterReceive = gms.balance - ghostReceive;
        booRef.transfer(ghostOwner, ghostReceive);
        booRef.transfer(gms.busterPlayer, busterReceive);
      }
      level.updateExp(tokenId, false, difficulty);
      for (uint256 i = 0; i < gms.numberOfBusters; i++) {
        level.updateExp(gms.busterTokenIds[i], true, difficulty);
      }
      emit GameComplete(gms.busterPlayer, ghostOwner, tokenId, sessionId, difficulty, busterReceive, ghostReceive);
    } else {
      booRef.transfer(ghostOwner, gms.balance);
      level.updateExp(tokenId, true, difficulty);
      for (uint256 i = 0; i < gms.numberOfBusters; i++) {
        level.updateExp(gms.busterTokenIds[i], false, difficulty);
      }
      emit GameComplete(ghostOwner, gms.busterPlayer, tokenId, sessionId, difficulty, gms.balance, 0);
    }

    TIDtoGhostMapSession[tokenId][sessionId].balance = 0;
    TIDtoGhostMapSession[tokenId][sessionId].active = false;

    for (uint256 i = 0; i < claimableSessions[ghostOwner].length; i++) {
      if (
        claimableSessions[ghostOwner][i].tokenId == tokenId && claimableSessions[ghostOwner][i].sessionId == sessionId
      ) {
        claimableSessions[ghostOwner][i] = claimableSessions[ghostOwner][claimableSessions[ghostOwner].length - 1];
        claimableSessions[ghostOwner].pop();
        return;
      }
    }
  }

  function pseudoRandom(address sender) internal returns (uint256) {
    return uint256(keccak256(abi.encodePacked(sender, tx.gasprice, block.timestamp, activeSessions.length, sender)));
  }

  function getLockedSession() public returns (Session memory) {
    return lockedSessions[_msgSender()];
  }

  // Public READ Game Method
  function getGhostMapSessionStats(uint256 tokenId, uint256 sessionId) public view returns (GhostMapSession memory) {
    return TIDtoGhostMapSession[tokenId][sessionId];
  }

  function getTokenIdActiveSessions(uint256 tokenId) public view returns (uint256[] memory) {
    return TIDtoActiveSessions[tokenId];
  }

  function getActiveSessions() public view returns (Session[] memory) {
    return activeSessions;
  }

  function stillActive(uint256 tokenId, uint256 sessionId) public view returns (bool) {
    return getGhostMapSessionStats(tokenId, sessionId).active;
  }

  function setAutoClaimServer(address autoClaimAddress) external onlyOwner {
    ACS = autoClaimAddress;
  }

  function createCommitment(
    uint256 tokenId,
    int256[2] calldata ghostPosition,
    uint256 nonce
  ) public pure returns (bytes32) {
    return bytes32(keccak256(abi.encodePacked(tokenId, ghostPosition[0], ghostPosition[1], nonce)));
  }
}

// SPDX-License-Identifier: MIT LICENSE
import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "./VerifySignature.sol";
pragma solidity ^0.8.0;

abstract contract Developers is Ownable {
  struct AddRemoveReveal {
    address developer;
    address[] forAddresses;
    string message;
    uint256 nonce;
    bytes signature;
  }

  address[] public developers;
  mapping(address => uint256) public addressToIndex;

  constructor(address[] memory _developers) {
    developers = _developers;
  }

  modifier onlyDeveloper {
    bool isDeveloper = false;
    for (uint256 i; i < developers.length; i++) {
      if (_msgSender() == developers[i]) {
        isDeveloper = true;
      }
    }
    require(isDeveloper, "You're not a developer, you can't make changes.");
    _;
  }

  function addDevelopers(address[] memory addresses, AddRemoveReveal[] calldata signatures) external onlyDeveloper {
    require(signatures.length == developers.length, "All developers must agree to onboard new developers");
    uint256 numberOfVerifiedDevelopers;

    AddRemoveReveal memory developerReveal;
    for (uint256 i = 0; i < signatures.length; i++) {
      require(
        keccak256(abi.encodePacked(addresses)) == keccak256(abi.encodePacked(developerReveal.forAddresses)),
        "Not adding the same addresses."
      );
      require(developers[addressToIndex[developerReveal.developer]] == developerReveal.developer, "Not a developer");
      developerReveal = signatures[i];
      if (
        !VerifySignature.verify(
          developerReveal.developer,
          developerReveal.forAddresses,
          developerReveal.message,
          developerReveal.nonce,
          developerReveal.signature
        )
      ) {
        revert("Signature incorrect.");
      }
      numberOfVerifiedDevelopers += 1;
    }

    require(numberOfVerifiedDevelopers == developers.length, "Not enough Signatures");

    for (uint256 i = 0; i < addresses.length; i++) {
      developers.push(addresses[i]);
    }
  }

  function removeDevelopers(address[] calldata addresses, AddRemoveReveal[] calldata signatures)
    external
    onlyDeveloper
  {}

  function getDevelopers() public returns (address[] memory) {
    return developers;
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >0.8.0;
import "../.deps/npm/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "./IHideNSeek.sol";
import "./PABStake.sol";

contract BOO is ERC20, Ownable {
  IHideNSeek public hidenseek;
  PABStake public pabstake;

  uint256 _cap;

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;

  constructor(uint256 cap_) ERC20("BOO", "BOO") {
    _cap = cap_;
  }

  /**
   * mints $BOO to a recipient
   * @param to the recipient of the $BOO
   * @param amount the amount of $BOO to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /**
   * burns $BOO from a holder
   * @param from the holder of the $BOO
   * @param amount the amount of $BOO to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  function cap() public view returns (uint256) {
    return _cap;
  }

  function capUpdate(uint256 _newCap) public onlyOwner {
    _cap = _newCap;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0)) {
      require(totalSupply() + amount <= _cap, "ERC20Capped: cap exceeded");
    }
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function setHideNSeek(address _hidenseek) external onlyOwner {
    hidenseek = IHideNSeek(_hidenseek);
    controllers[_hidenseek] = true;
  }

  function setPABStake(address _pabstake) external onlyOwner {
    pabstake = PABStake(_pabstake);
    controllers[_pabstake] = true;
  }

  function isController(address _controller) public view returns (bool) {
    return controllers[_controller];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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