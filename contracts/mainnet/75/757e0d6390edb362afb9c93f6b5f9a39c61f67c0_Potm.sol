// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Potm is VRFConsumerBase {
    struct Prize {
        string name;
        address winner;
        bool isClaimed;
    }

    Prize[] public prizes;
    mapping(address => uint256) public ticketsPerParticipant;
    mapping(address => uint256) public initialTicketsPerParticipant;
    mapping(bytes32 => uint256) private requestIdToPrizeIndex;

    address[] public participants;
    bool public hasDrawn = false;
    address public owner;
    uint256 public claimDeadline;
    uint256 constant CLAIM_DURATION = 7 days;

    bytes32 internal keyHash;
    uint256 internal fee;

    event PrizeDrawn(string prizeName, address winner);
    event PrizeClaimed(string prizeName, address claimer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() 
        VRFConsumerBase(
            0x41034678D6C633D8a95c75e1138A360a28bA15d1, // VRFCoordinator for Ethereum Mainnet
            0xf97f4df75117a78c1A5a0DBb814Af92458539FB4  // LINK Token Address
        ) 
    {
        owner = msg.sender;
        keyHash = 0x72d2b016bb5b62912afea355ebf33b91319f828738b111b723b78696b9847b63;
        fee = 0.1 * 10 ** 18; // 0.1 LINK

        initializePrizes();
    }

    function initializePrizes() private {
        prizes.push(Prize("Pudgy Penguin #196", address(0), false));
        prizes.push(Prize("Lil Pudgy #16565", address(0), false));
        prizes.push(Prize("Lil Pudgy #18590", address(0), false));
        prizes.push(Prize("Lil Pudgy #18584", address(0), false));
        prizes.push(Prize("Lil Pudgy #20259", address(0), false));
        prizes.push(Prize("10000 PINGU", address(0), false));
        prizes.push(Prize("9000 PINGU", address(0), false));
        prizes.push(Prize("8000 PINGU", address(0), false));
        prizes.push(Prize("7000 PINGU", address(0), false));
        prizes.push(Prize("6000 PINGU", address(0), false));
        prizes.push(Prize("5000 PINGU", address(0), false));
        prizes.push(Prize("4500 PINGU", address(0), false));
        prizes.push(Prize("4000 PINGU", address(0), false));
        prizes.push(Prize("3500 PINGU", address(0), false));
        prizes.push(Prize("3000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
    }

    function addParticipants(address[] memory _participants, uint256[] memory _tickets) public onlyOwner {
        require(_participants.length == _tickets.length, "Participants and tickets must match");
        for (uint i = 0; i < _participants.length; i++) {
            require(ticketsPerParticipant[_participants[i]] == 0, "Participant already added");
            ticketsPerParticipant[_participants[i]] = _tickets[i];
            initialTicketsPerParticipant[_participants[i]] = _tickets[i];
            participants.push(_participants[i]);
        }
    }

    function drawPrizes() public onlyOwner {
        require(!hasDrawn, "Draw has already been performed");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        hasDrawn = true;
        claimDeadline = block.timestamp + CLAIM_DURATION;

        for (uint i = 0; i < prizes.length; i++) {
            bytes32 requestId = requestRandomness(keyHash, fee);
            requestIdToPrizeIndex[requestId] = i;
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 prizeIndex = requestIdToPrizeIndex[requestId];
        uint256 totalTickets = getTotalTickets();
        uint256 winnerIndex = getRandomWinnerIndex(randomness, totalTickets);
        prizes[prizeIndex].winner = participants[winnerIndex];
        emit PrizeDrawn(prizes[prizeIndex].name, participants[winnerIndex]);
    }

    function getTotalTickets() private view returns (uint256 totalTickets) {
        for (uint i = 0; i < participants.length; i++) {
            totalTickets += ticketsPerParticipant[participants[i]];
        }
    }

    function getRandomWinnerIndex(uint256 randomness, uint256 totalTickets) private view returns (uint256) {
        uint256 sum = 0;
        uint256 random = randomness % totalTickets;
        for (uint i = 0; i < participants.length; i++) {
            sum += ticketsPerParticipant[participants[i]];
            if (random < sum) {
                return i;
            }
        }
        return 0;
    }

    function claimPrize(uint256 prizeIndex) public {
        require(prizes[prizeIndex].winner == msg.sender, "You are not the winner of this prize");
        require(block.timestamp <= claimDeadline, "Claim period has ended");
        require(!prizes[prizeIndex].isClaimed, "Prize already claimed");
        prizes[prizeIndex].isClaimed = true;
        emit PrizeClaimed(prizes[prizeIndex].name, msg.sender);
    }

    function withdrawToken(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "./LinkTokenInterface.sol";

import {VRFRequestIDBase} from "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  LinkTokenInterface internal immutable LINK;
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  // solhint-disable-next-line chainlink-solidity/prefix-storage-variables-with-s-underscore
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */ private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
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