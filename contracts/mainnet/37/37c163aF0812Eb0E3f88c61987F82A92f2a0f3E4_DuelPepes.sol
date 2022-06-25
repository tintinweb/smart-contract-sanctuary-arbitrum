// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
                                Duel Pepes
                      On-chain duelling game between NFTs
*/

contract DuelPepes is Ownable {

    using ECDSA for bytes32;

    struct Duel {
      // unique identifier for duel (salt)
      bytes32 identifier;
      // 0 index = creator, 1 index = challenger
      address[2] duellors;
      // Wager amount in token
      uint wager;
      // Token to wager in
      address token;
      // Fees at the time of duel creation
      uint fees;
      // NFTs duelling. 
      // Collections = address of collection duelling
      // IDs = # id of nfts in collections
      // 0 index = creator, 1 index = challenger
      address[2] collections;
      uint[2] ids;
      // Initial hashed move set signature when creating duel
      bytes initialMovesSignature;
      // Moves selected by duel participants
      // 0 index = creator, 1 index = challenger
      uint[5][2] moves;
      // Who won the duel
      bool isCreatorWinner;
      // 0 index - Time created, 1 index - time challenged, 2 - time decided
      uint[3] timestamps;
    }

    struct LeaderboardPosition {
      // 0 - Total damage incurred, 1 - Total damage dealt
      uint[2] damage;
      // Total wins
      uint wins;
      // Total losses
      uint losses;
      // Total draws
      uint draws;
      // Total winnings from wagers
      uint winnings;
    }

    enum Moves {
      // Accurate [1, 1, 0]
      Punch,
      // Strength [2, 0, 0]
      Kick,
      // Defense [0, 0, 3]
      Block,
      // Special attack [3, 0, 0]
      Special
    }

    // Fee collector address
    address public feeCollector;
    // Map duel ID to duel
    mapping (uint => Duel) public duels;
    // Map unique identifier to duel ID
    mapping (bytes32 => uint) public duelIdentifiers;
    // Whitelisted collections
    mapping (address => bool) public whitelistedCollections;
    // # of duels 
    uint public duelCount;
    // Fees in %
    uint public fees;
    // Percentage precision multiplier
    uint public percentagePrecision = 10 ** 4;
    // Time limit for a duel to be challenged
    uint public challengeTimelimit = 12 hours;
    // Time limit for duel moves to be revealed
    uint public revealTimeLimit = 12 hours;
    // Maps duellor addresses to duel IDs
    mapping (address => uint[]) public userDuels;
    // Maps move enum to it's attack and defence attributes
    // [0] - damage, [1] - guaranteed damage, [2] - defense
    mapping (uint => uint[3]) public moveAttributes;
    // Leaderboard for NFTs
    // mapping (Collection => Id)
    mapping (address => mapping(uint => LeaderboardPosition)) public nftLeaderboard;
    // Leaderboard for users
    mapping (address => LeaderboardPosition) public userLeaderboard;

    event LogNewDuel(uint indexed id, address indexed creator);
    event LogChallengedDuel(uint indexed id, address indexed challenger, address indexed creator);
    event LogDecidedDuel(uint indexed id, address indexed creator, address indexed challenger, bool isCreatorWinner);
    event LogAddToWhitelist(address collection);

    constructor(address _feeCollector) {
      require(_feeCollector != address(0), "Invalid fee collector address");
      feeCollector = _feeCollector;
      moveAttributes[uint(Moves.Punch)] = [1, 1, 0];
      moveAttributes[uint(Moves.Kick)]  = [2, 0, 0];
      moveAttributes[uint(Moves.Block)] = [0, 0, 3];
      moveAttributes[uint(Moves.Special)] = [3, 0, 0];
    }

    /**
    * Retrieve a specific duel
    * @param _id identifier of the duel
    * @return Duel struct
    */
    function getDuel(uint _id)
    public
    view
    returns (Duel memory) {
        return duels[_id];
    }

    /**
    * Adds a new collection to the whitelist
    * @param _collection Address of collection
    * @return Whether collection was added
    */
    function addToWhitelist(address _collection)
    public
    onlyOwner
    returns (bool) {
      require(_collection != address(0), "Invalid address");
      require(!whitelistedCollections[_collection], "Collection already whitelisted");

      whitelistedCollections[_collection] = true;

      emit LogAddToWhitelist(_collection);

      return true;
    }

    /**
    * Creates a new duel
    * @param identifier Unique identifier for duel
    * @param wager Amount to wager in `token`
    * @param token Token to wager in
    * @param collection Valid NFT collection to duel
    * @param nftId ID of NFT in `collection` to duel
    * @param movesSig Signature of moves set for duel
    * @return Whether duel was created
    */
    function createDuel(
      bytes32 identifier,
      uint wager,
      address token,
      address collection,
      uint nftId,
      bytes memory movesSig
    )
    public
    returns (bool) {
      require(duelIdentifiers[identifier] == 0 && identifier != 0, "Invalid duel identifier");
      require(wager > 0, "Wager must be greater than 0");
      require(token != address(0), "Invalid token");
      require(whitelistedCollections[collection], "Collection not whitelisted for duels");
      require(IERC721(collection).ownerOf(nftId) == msg.sender, "Sender does not own NFT");

      // Duel IDs are 1-indexed
      duels[++duelCount].identifier = identifier;
      duelIdentifiers[identifier] = duelCount;

      duels[duelCount].duellors[0] = msg.sender;
      duels[duelCount].wager = wager;
      duels[duelCount].token = token;
      duels[duelCount].fees = wager * 2 * fees / percentagePrecision;
      duels[duelCount].collections[0] = collection;
      duels[duelCount].ids[0] = nftId;
      duels[duelCount].initialMovesSignature = movesSig;
      duels[duelCount].timestamps[0] = block.timestamp;
      
      IERC20(token).transferFrom(msg.sender, address(this), wager);

      emit LogNewDuel(duelCount, msg.sender);

      return true;
    }

    /**
    * Recover funds from a non-matched duel
    * @param id Duel id
    */
    function undoDuel(
      uint id
    )
    public
    returns (bool) {
      require(
        block.timestamp >
        duels[id].timestamps[0] + revealTimeLimit,
        "Challenge time limit not passed"
      );
      require(
        duels[id].duellors[1] == address(0)
      );
      require(
        duels[id].timestamps[2] == 0,
        "Duel outcome was already decided"
      );

      // Save timestamp
      duels[id].timestamps[2] = block.timestamp;

      IERC20(duels[id].token).transfer(
        duels[id].duellors[0],
        duels[id].wager
      );

      return true;
    }

    /**
    * Claim funds when opponent does not reveal within the time window
    * @param id Duel id
    */
    function claimForfeit(
      uint id
    )
    public
    returns (bool) {
      require(
        block.timestamp >
        duels[id].timestamps[0] + revealTimeLimit,
        "Reveal time limit not passed"
      );

      require(
        duels[id].timestamps[2] == 0,
        "Duel outcome was already decided"
      );

      // Save timestamp
      duels[id].timestamps[2] = block.timestamp;

      // Save winner
      duels[id].isCreatorWinner = false;

      // Update NFT leaderboard position
      _updateNftLeaderboard(
        id,
        false, // is draw
        0,
        1 // challenger damage
      );

      // Update user leaderboard position
      _updateUserLeaderboard(
        id,
        false, // is draw
        0,
        1 // challenger damage
      );

      // Transfer funds to winner
      IERC20(duels[id].token).transfer(
        duels[id].duellors[1],
        duels[id].wager * 2 - duels[id].fees
      );

      return true;
    }

    /**
    * Challenges a duel
    * @param id Duel ID
    * @param collection Valid NFT collection to duel
    * @param nftId ID of NFT in `collection` to duel
    * @param moves 5 moves to submit for duel
    * @return Whether duel was created
    */
    function challenge(
      uint id,
      address collection,
      uint nftId,
      uint[5] memory moves
    )
    public
    returns (bool) {
      require(
        duels[id].duellors[0] != address(0) && duels[id].duellors[1] == address(0), 
        "Invalid duel ID"
      );
      require(duels[id].duellors[0] != msg.sender, "Creator cannot duel themselves");
      require(whitelistedCollections[collection], "Collection not whitelisted for duels");
      require(IERC721(collection).ownerOf(nftId) == msg.sender, "Sender does not own NFT");
      require(validateMoves(moves), "Invalid moves");
      require(
        block.timestamp <= 
        duels[id].timestamps[0] + challengeTimelimit, 
        "Challenge time limit passed"
      );

      duels[id].duellors[1] = msg.sender;
      duels[id].collections[1] = collection;
      duels[id].ids[1] = nftId;
      duels[id].moves[1] = moves;
      duels[id].timestamps[1] = block.timestamp;
      
      IERC20(duels[id].token).transferFrom(msg.sender, address(this), duels[id].wager);

      emit LogChallengedDuel(id, msg.sender, duels[id].duellors[0]);

      return true;
    }

    /**
    * Reveal initial moves for a duel. Receive a bonus for revealing in time if you lose.
    * @param id Duel ID
    * @param moves Initial 5 moves submitted for duel
    */
    function revealDuel(
      uint id,
      uint[5] memory moves
    )
    public
    returns (bool) {
      require(msg.sender == duels[id].duellors[0], "Invalid sender");
      require(
        block.timestamp <= 
        duels[id].timestamps[1] + revealTimeLimit, 
        "Reveal time limit passed"
      );
      require(
        duels[id].timestamps[2] == 0,
        "Duel outcome was already decided"
      );

      bytes32 movesHash = keccak256(
        abi.encodePacked(
          duels[id].identifier,
          moves[0],
          moves[1],
          moves[2],
          moves[3],
          moves[4]
        )
      );
      bytes32 ethSigHash = keccak256(
        abi.encodePacked(
          "\x19Ethereum Signed Message:\n32", 
          movesHash
        )
      );
      require(
        verify(ethSigHash, duels[id].initialMovesSignature, msg.sender),
        "Moves don't match initial submitted moves"
      );

      // Save creator moves
      for (uint i = 0; i < 5; i++)
        duels[id].moves[0][i] = moves[i];

      // Decide outcome of the duel
      (uint creatorDamage, uint challengerDamage) = decideDuel(
        id
      );

      // Save timestamp
      duels[id].timestamps[2] = block.timestamp;

      if (challengerDamage != creatorDamage) {
        // Save winner
        duels[id].isCreatorWinner = challengerDamage > creatorDamage;
        // Update NFT leaderboard position
        _updateNftLeaderboard(
          id,
          false, // is draw
          creatorDamage,
          challengerDamage
        );
        // Update user leaderboard position
        _updateUserLeaderboard(
          id,
          false, // is draw
          creatorDamage,
          challengerDamage
        );

        // Transfer funds to winner
        IERC20(duels[id].token).transfer(
          duels[id].duellors[duels[id].isCreatorWinner ? 0 : 1],
          duels[id].wager * 2 - duels[id].fees
        );

        uint256 revealTimeRemaining = duels[id].timestamps[1] + revealTimeLimit - block.timestamp;

        // max 20% bonus linear decreasing if you lose but reveal immediately
        uint256 bonus;

        if (duels[id].isCreatorWinner) {
           bonus = 0;
        } else {
           bonus = (duels[id].fees * 20 / 100) * revealTimeRemaining / revealTimeLimit;

           // Transfer bonus to revealer
           IERC20(duels[id].token).transfer(
             duels[id].duellors[0],
             bonus
           );
        }

        // Transfer fees to fee collector
        IERC20(duels[id].token).transfer(
          feeCollector,
          duels[id].fees - bonus
        );
      } else {
        // Update NFT leaderboard
        _updateNftLeaderboard(
          id,
          true, // is draw
          creatorDamage,
          challengerDamage
        );
        // Update user leaderboard position
        _updateUserLeaderboard(
          id,
          false, // is draw
          creatorDamage,
          challengerDamage
        );
        // Return funds to creator (minus fees)
        IERC20(duels[id].token).transfer(
          duels[id].duellors[0],
          duels[id].wager - (duels[id].fees/2)
        );
        // Return funds to challenger (minus fees)
        IERC20(duels[id].token).transfer(
          duels[id].duellors[1],
          duels[id].wager - (duels[id].fees/2)
        );
        // Transfer fees to fee collector
        IERC20(duels[id].token).transfer(
          feeCollector,
          duels[id].fees
        );
      }

      emit LogDecidedDuel(
        id, 
        duels[id].duellors[0], 
        duels[id].duellors[1], 
        duels[id].isCreatorWinner
      );

      return true;
    }

    /**
    * Updates leaderboard position for NFTs involved in a decided duel
    * @param id Duel ID
    * @param isDraw Whether the duel was a draw
    * @param creatorDamage Damaged dealt to creator
    * @param challengerDamage Damaged dealt to challenger
    */
    function _updateNftLeaderboard(
      uint id,
      bool isDraw,
      uint creatorDamage,
      uint challengerDamage
    ) internal {
        // Add to NFT leaderboard position
        // Damage incurred by creator
        nftLeaderboard
          [duels[id].collections[0]]
          [duels[id].ids[0]].damage[0] = creatorDamage;
        // Damage incurred by challenger
        nftLeaderboard
          [duels[id].collections[1]]
          [duels[id].ids[1]].damage[0] = challengerDamage;
        // Damage dealt by creator
        nftLeaderboard
          [duels[id].collections[0]]
          [duels[id].ids[0]].damage[1] = challengerDamage;
        // Damage dealt by challenger
        nftLeaderboard
          [duels[id].collections[1]]
          [duels[id].ids[1]].damage[1] = creatorDamage;
        if (!isDraw) {
          uint winner = duels[id].isCreatorWinner ? 0 : 1;
          uint loser = duels[id].isCreatorWinner ? 1 : 0;
          // Add to stats
          nftLeaderboard
            [duels[id].collections[winner]]
            [duels[id].ids[winner]].wins += 1;
          nftLeaderboard
            [duels[id].collections[loser]]
            [duels[id].ids[loser]].losses += 1;
          nftLeaderboard
            [duels[id].collections[winner]]
            [duels[id].ids[winner]].winnings += duels[id].wager * 2 - duels[id].fees;
        } else {
          nftLeaderboard
            [duels[id].collections[0]]
            [duels[id].ids[0]].draws += 1;
          nftLeaderboard
            [duels[id].collections[1]]
            [duels[id].ids[1]].draws += 1;
        }
    }

    /**
    * Updates leaderboard position for users involved in a decided duel
    * @param id Duel ID
    * @param isDraw Whether the duel was a draw
    * @param creatorDamage Damaged dealt to creator
    * @param challengerDamage Damaged dealt to challenger
    */
    function _updateUserLeaderboard(
      uint id,
      bool isDraw,
      uint creatorDamage,
      uint challengerDamage
    ) internal {
        // Add to NFT leaderboard position
        // Damage incurred by creator
        userLeaderboard
          [duels[id].duellors[0]].damage[0] = creatorDamage;
        // Damage incurred by challenger
        userLeaderboard
          [duels[id].duellors[1]].damage[0] = challengerDamage;
        // Damage dealt by creator
        userLeaderboard
          [duels[id].duellors[0]].damage[1] = challengerDamage;
        // Damage dealt by challenger
        userLeaderboard
          [duels[id].duellors[1]].damage[1] = creatorDamage;
        if (!isDraw) {
          uint winner = duels[id].isCreatorWinner ? 0 : 1;
          uint loser = duels[id].isCreatorWinner ? 1 : 0;
          // Add to stats
          userLeaderboard
            [duels[id].duellors[winner]].wins += 1;
          userLeaderboard
            [duels[id].duellors[loser]].losses += 1;
          userLeaderboard
            [duels[id].duellors[winner]].winnings += duels[id].wager * 2 - duels[id].fees;
        } else {
          userLeaderboard
            [duels[id].duellors[0]].draws += 1;
          userLeaderboard
            [duels[id].duellors[1]].draws += 1;
        }
    }

    function verify(
      bytes32 data,
      bytes memory signature,
      address account
    ) public pure returns (bool) {
        return data.recover(signature) == account;
    }

    /**
    * Validate a move set
    * @param moves 5 move set
    * @return Whether moves are valid
    */
    function validateMoves(
      uint[5] memory moves
    )
    public
    view
    returns (bool) {
      // Occurences of each move in terms of enum
      uint[4] memory occurences;
      for (uint i = 0; i < 5; i++) {
        require(moves[i] <= uint(Moves.Special), "Invalid move");
        if (moves[i] != uint(Moves.Special))
          require(occurences[moves[i]] + 1 <= 2, "Each move can only be performed twice");
        else
          require(occurences[moves[i]] + 1 <= 1, "Special moves can only be performed once");
        occurences[moves[i]] += 1;
      }
      return true;
    }

    /**
    * Decides the winner of a duel based on creator and challeger moves
    * @param id Duel id
    * @return creatorDamage Damage dealt to creator
    * @return challengerDamage Damage dealt to challenger
    */
    function decideDuel(
      uint id
    ) 
    public
    view
    returns (uint creatorDamage, uint challengerDamage) {
      uint creatorDamage;
      uint challengerDamage;

      for (uint i = 0; i < 5; i++) {
        uint creatorMove = duels[id].moves[0][i];
        uint challengerMove = duels[id].moves[1][i];
        // Damage
        creatorDamage += creatorMove == uint(Moves.Block) ? 0 : moveAttributes[challengerMove][0];
        challengerDamage += challengerMove == uint(Moves.Block) ? 0 : moveAttributes[creatorMove][0];

        // Guaranteed damage
        creatorDamage += challengerMove == uint(Moves.Punch) ? moveAttributes[challengerMove][1] : 0;
        challengerDamage += creatorMove == uint(Moves.Punch) ? moveAttributes[creatorMove][1] : 0;
      }

      return (creatorDamage, challengerDamage);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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