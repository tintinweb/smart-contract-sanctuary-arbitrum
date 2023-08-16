// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IChronicle} from "chronicle-std/IChronicle.sol";

import {IScribeOptimistic} from "./IScribeOptimistic.sol";

import {IScribe} from "./IScribe.sol";
import {Scribe} from "./Scribe.sol";

import {LibSchnorr} from "./libs/LibSchnorr.sol";
import {LibSecp256k1} from "./libs/LibSecp256k1.sol";

/**
 * @title ScribeOptimistic
 *
 * @notice Scribe based optimistic Oracle with onchain fault resolution
 */
contract ScribeOptimistic is IScribeOptimistic, Scribe {
    using LibSchnorr for LibSecp256k1.Point;
    using LibSecp256k1 for LibSecp256k1.Point;
    using LibSecp256k1 for LibSecp256k1.Point[];

    /// @dev The initial opChallengePeriod set during construction.
    uint16 private constant _INITIAL_OP_CHALLENGE_PERIOD = 1 hours;

    // -- Storage --

    /// @inheritdoc IScribeOptimistic
    uint16 public opChallengePeriod;

    /// @inheritdoc IScribeOptimistic
    uint8 public opFeedIndex;

    /// @dev The truncated hash of the schnorrData provided in last opPoke.
    ///      Binds the opFeed to their schnorrData.
    uint160 internal _schnorrDataCommitment;

    /// @dev The age of the pokeData provided in last opPoke.
    ///      Ensures Schnorr signature can be verified after setting pokeData's
    ///      age to block.timestamp during opPoke.
    uint32 internal _originalOpPokeDataAge;

    /// @dev opScribe's last opPoke'd value and corresponding age.
    PokeData internal _opPokeData;

    /// @inheritdoc IScribeOptimistic
    uint public maxChallengeReward;

    // -- Constructor and Receive Functionality --

    constructor(address initialAuthed, bytes32 wat_)
        Scribe(initialAuthed, wat_)
    {
        // Note to have a non-zero challenge period.
        _setOpChallengePeriod(_INITIAL_OP_CHALLENGE_PERIOD);
    }

    receive() external payable {}

    // -- Poke Functionality --

    function _poke(PokeData calldata pokeData, SchnorrData calldata schnorrData)
        internal
        override(Scribe)
    {
        // Load current age from storage.
        uint32 age = _currentPokeData().age;

        // Revert if pokeData stale.
        if (pokeData.age <= age) {
            revert StaleMessage(pokeData.age, age);
        }
        // Revert if pokeData from the future.
        if (pokeData.age > uint32(block.timestamp)) {
            revert FutureMessage(pokeData.age, uint32(block.timestamp));
        }

        // Revert if schnorrData does not prove integrity of pokeData.
        bool ok;
        bytes memory err;
        // forgefmt: disable-next-item
        (ok, err) = _verifySchnorrSignature(
            constructPokeMessage(pokeData),
            schnorrData
        );
        if (!ok) {
            _revert(err);
        }

        // Store pokeData's val in _pokeData storage and set its age to now.
        _pokeData.val = pokeData.val;
        _pokeData.age = uint32(block.timestamp);

        emit Poked(msg.sender, pokeData.val, pokeData.age);
    }

    // -- opPoke Functionality --

    /// @dev Optimized function selector: 0x00000000.
    ///      Note that this function is _not_ defined via the IScribe interface
    ///      and one should _not_ depend on it.
    function opPoke_optimized_397084999(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData,
        ECDSAData calldata ecdsaData
    ) external payable {
        _opPoke(pokeData, schnorrData, ecdsaData);
    }

    /// @inheritdoc IScribeOptimistic
    function opPoke(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData,
        ECDSAData calldata ecdsaData
    ) external {
        _opPoke(pokeData, schnorrData, ecdsaData);
    }

    function _opPoke(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData,
        ECDSAData calldata ecdsaData
    ) internal {
        // Load _opPokeData from storage.
        PokeData memory opPokeData = _opPokeData;

        // Decide whether _opPokeData finalized.
        bool opPokeDataFinalized =
            opPokeData.age + opChallengePeriod <= uint32(block.timestamp);

        // Revert if _opPokeData not finalized, i.e. still challengeable.
        if (!opPokeDataFinalized) {
            revert InChallengePeriod();
        }

        // Decide current age.
        uint32 age =
            opPokeData.age > _pokeData.age ? opPokeData.age : _pokeData.age;

        // Revert if pokeData stale.
        if (pokeData.age <= age) {
            revert StaleMessage(pokeData.age, age);
        }
        // Revert if pokeData from the future.
        if (pokeData.age > uint32(block.timestamp)) {
            revert FutureMessage(pokeData.age, uint32(block.timestamp));
        }

        // Recover ECDSA signer.
        address signer = ecrecover(
            _constructOpPokeMessage(pokeData, schnorrData),
            ecdsaData.v,
            ecdsaData.r,
            ecdsaData.s
        );

        // Load signer's index.
        uint signerIndex = _feeds[signer];

        // Revert if signer not feed.
        if (signerIndex == 0) {
            revert SignerNotFeed(signer);
        }

        // Store the signerIndex as opFeedIndex and bind them to their provided
        // schnorrData.
        //
        // Note that cast is safe as _feed's image is [0, _pubKeys.length) and
        // _pubKeys' length is bounded by maxFeeds, i.e. type(uint8).max - 1.
        opFeedIndex = uint8(signerIndex);
        _schnorrDataCommitment = uint160(
            uint(
                keccak256(
                    abi.encodePacked(
                        schnorrData.signature,
                        schnorrData.commitment,
                        schnorrData.signersBlob
                    )
                )
            )
        );

        // If _opPokeData provides the current val, move it to the _pokeData
        // storage to free _opPokeData storage. If the current val is provided
        // by _pokeData, _opPokeData can be overwritten.
        if (opPokeData.age == age) {
            _pokeData = opPokeData;
        }

        // Store provided pokeData's val in _opPokeData storage.
        _opPokeData.val = pokeData.val;
        _opPokeData.age = uint32(block.timestamp);

        // Store pokeData's age to allow recreating original pokeMessage.
        _originalOpPokeDataAge = pokeData.age;

        emit OpPoked(msg.sender, signer, schnorrData, pokeData);
    }

    /// @inheritdoc IScribeOptimistic
    function opChallenge(SchnorrData calldata schnorrData)
        external
        returns (bool)
    {
        // Load _opPokeData from storage.
        PokeData memory opPokeData = _opPokeData;

        // Decide whether _opPokeData is challengeable.
        bool opPokeDataChallengeable =
            opPokeData.age + opChallengePeriod > uint32(block.timestamp);

        // Revert if _opPokeData is not challengeable.
        if (!opPokeDataChallengeable) {
            revert NoOpPokeToChallenge();
        }

        // Construct truncated hash from schnorrData.
        uint160 schnorrDataHash = uint160(
            uint(
                keccak256(
                    abi.encodePacked(
                        schnorrData.signature,
                        schnorrData.commitment,
                        schnorrData.signersBlob
                    )
                )
            )
        );

        // Revert if schnorrDataHash does not match _schnorrDataCommitment.
        if (schnorrDataHash != _schnorrDataCommitment) {
            revert SchnorrDataMismatch(schnorrDataHash, _schnorrDataCommitment);
        }

        // Decide whether schnorrData verifies opPokeData.
        bool ok;
        bytes memory err;
        (ok, err) = _verifySchnorrSignature(
            constructPokeMessage(
                PokeData({val: opPokeData.val, age: _originalOpPokeDataAge})
            ),
            schnorrData
        );

        if (ok) {
            // Decide whether _opPokeData stale already.
            bool opPokeDataStale = opPokeData.age <= _pokeData.age;

            // If _opPokeData not stale, finalize it by moving it to the
            // _pokeData storage. Note to also clean the _opPokeData storage to
            // not block new opPoke's as _opPokeData's challenge period not over.
            if (!opPokeDataStale) {
                _pokeData = _opPokeData;
                delete _opPokeData;
            }

            emit OpPokeChallengedUnsuccessfully(msg.sender);
        } else {
            // Drop opFeed and delete invalid _opPokeData.
            // Note to use address(this) as caller to indicate self-governed
            // drop of feed.
            _drop(address(this), opFeedIndex);

            // Pay ETH reward to challenger.
            uint reward = challengeReward();
            if (_sendETH(payable(msg.sender), reward)) {
                emit OpChallengeRewardPaid(msg.sender, reward);
            }

            emit OpPokeChallengedSuccessfully(msg.sender, err);
        }

        // Return whether challenging was successful.
        return !ok;
    }

    /// @inheritdoc IScribeOptimistic
    function constructOpPokeMessage(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData
    ) external view returns (bytes32) {
        return _constructOpPokeMessage(pokeData, schnorrData);
    }

    function _constructOpPokeMessage(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        wat,
                        pokeData.val,
                        pokeData.age,
                        schnorrData.signature,
                        schnorrData.commitment,
                        schnorrData.signersBlob
                    )
                )
            )
        );
    }

    // -- Toll'ed Read Functionality --

    // - IChronicle Functions

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function read()
        external
        view
        override(IChronicle, Scribe)
        toll
        returns (uint)
    {
        uint val = _currentPokeData().val;
        require(val != 0);
        return val;
    }

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function tryRead()
        external
        view
        override(IChronicle, Scribe)
        toll
        returns (bool, uint)
    {
        uint val = _currentPokeData().val;
        return (val != 0, val);
    }

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function readWithAge()
        external
        view
        override(IChronicle, Scribe)
        toll
        returns (uint, uint)
    {
        PokeData memory pokeData = _currentPokeData();
        require(pokeData.val != 0);
        return (pokeData.val, pokeData.age);
    }

    function tryReadWithAge()
        external
        view
        override(IChronicle, Scribe)
        toll
        returns (bool, uint, uint)
    {
        PokeData memory pokeData = _currentPokeData();
        return (pokeData.val != 0, pokeData.val, pokeData.age);
    }

    // - MakerDAO Compatibility

    /// @inheritdoc IScribe
    /// @dev Only callable by toll'ed address.
    function peek()
        external
        view
        override(IScribe, Scribe)
        toll
        returns (uint, bool)
    {
        uint val = _currentPokeData().val;
        return (val, val != 0);
    }

    // - Chainlink Compatibility

    /// @inheritdoc IScribe
    /// @dev Only callable by toll'ed address.
    function latestRoundData()
        external
        view
        override(IScribe, Scribe)
        toll
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        )
    {
        PokeData memory pokeData = _currentPokeData();

        roundId = 1;
        answer = int(uint(pokeData.val));
        // assert(uint(answer) == uint(pokeData.val));
        startedAt = 0;
        updatedAt = pokeData.age;
        answeredInRound = roundId;
    }

    function _currentPokeData() internal view returns (PokeData memory) {
        // Load pokeData slots from storage.
        PokeData memory pokeData = _pokeData;
        PokeData memory opPokeData = _opPokeData;

        // Decide whether _opPokeData is finalized.
        bool opPokeDataFinalized =
            opPokeData.age + opChallengePeriod <= uint32(block.timestamp);

        // Decide and return current pokeData.
        if (opPokeDataFinalized && opPokeData.age > pokeData.age) {
            return opPokeData;
        } else {
            return pokeData;
        }
    }

    // -- Auth'ed Functionality --

    /// @inheritdoc IScribeOptimistic
    function setOpChallengePeriod(uint16 opChallengePeriod_) external auth {
        _setOpChallengePeriod(opChallengePeriod_);
    }

    function _setOpChallengePeriod(uint16 opChallengePeriod_) internal {
        require(opChallengePeriod_ != 0);

        if (opChallengePeriod != opChallengePeriod_) {
            emit OpChallengePeriodUpdated(
                msg.sender, opChallengePeriod, opChallengePeriod_
            );
            opChallengePeriod = opChallengePeriod_;
        }

        _afterAuthedAction();
    }

    function _drop(address caller, uint feedIndex) internal override(Scribe) {
        super._drop(caller, feedIndex);

        _afterAuthedAction();
    }

    function _setBar(uint8 bar_) internal override(Scribe) {
        super._setBar(bar_);

        _afterAuthedAction();
    }

    /// @dev Ensures an auth'ed configuration update does not enable
    ///      successfully challenging a prior to the update valid opPoke.
    ///
    /// @custom:invariant Val is provided if _pokeData prior to the tx is
    ///                   non-empty. Note that this is the case if there were
    ///                   at least two valid calls ∊ {poke, opPoke}.
    ///                     preTx(_pokeData) != (0, 0)
    ///                       → (true, _) = postTx(tryRead())
    /// @custom:invariant Val is provided via _pokeData after the tx.
    ///                     postTx(readWithAge()) = postTx(_pokeData)
    /// @custom:invariant _opPokeData is empty after the tx.
    ///                     (0, 0) = postTx(_opPokeData)
    function _afterAuthedAction() internal {
        // Do nothing during deployment.
        if (address(this).code.length == 0) return;

        // Load _opPokeData from storage.
        PokeData memory opPokeData = _opPokeData;

        // Decide whether _opPokeData is finalized.
        //
        // Note that the decision is based on the possibly updated
        // opChallengePeriod! This means a once finalized opPoke may be dropped
        // if the opChallengePeriod was increased.
        bool opPokeDataFinalized =
            opPokeData.age + opChallengePeriod <= uint32(block.timestamp);

        // Note that _opPokeData is in one of the following three states:
        // 1. finalized and newer than _pokeData
        // 2. finalized but older than _pokeData
        // 3. non-finalized
        //
        // Note that for state 1 _opPokeData can be moved to _pokeData and
        // afterwards deleted.
        // Note that for state 2 and 3 _opPokeData can be directly deleted.

        // If _opPokeData is in state 1, move it to the _pokeData storage.
        //
        // Note that this ensures the current value is provided via _pokeData.
        if (opPokeDataFinalized && opPokeData.age > _pokeData.age) {
            _pokeData = opPokeData;
        }

        // If _opPokeData is in state 3, emit event to indicate a possibly valid
        // opPoke was dropped.
        if (!opPokeDataFinalized) {
            emit OpPokeDataDropped(msg.sender, opPokeData);
        }

        // Now it is safe to delete _opPokeData.
        delete _opPokeData;

        // Note that the current value is now provided via _pokeData.
        // assert(_currentPokeData().val == _pokeData.val);
        // assert(_currentPokeData().age == _pokeData.age);

        // Set the age of contract's current value to block.timestamp.
        //
        // Note that this ensures an already signed, but now possibly invalid
        // with regards to contract configurations, opPoke payload cannot be
        // opPoke'd anymore.
        _pokeData.age = uint32(block.timestamp);
    }

    // -- Searcher Incentivization Logic --

    /// @inheritdoc IScribeOptimistic
    function challengeReward() public view returns (uint) {
        uint balance = address(this).balance;
        return balance > maxChallengeReward ? maxChallengeReward : balance;
    }

    /// @inheritdoc IScribeOptimistic
    function setMaxChallengeReward(uint maxChallengeReward_) external auth {
        if (maxChallengeReward != maxChallengeReward_) {
            emit MaxChallengeRewardUpdated(
                msg.sender, maxChallengeReward, maxChallengeReward_
            );
            maxChallengeReward = maxChallengeReward_;
        }
    }

    function _sendETH(address payable to, uint amount)
        internal
        returns (bool)
    {
        (bool ok,) = to.call{value: amount}("");
        return ok;
    }
}

/**
 * @dev Contract overwrite to deploy contract instances with specific naming.
 *
 *      For more info, see docs/Deployment.md.
 */
contract Chronicle_ETH_USD_smokes9 is ScribeOptimistic {
    // @todo       ^^^^ ^^^^^ ^^^^^^^ Adjust name of Scribe instance.
    constructor(address initialAuthed, bytes32 wat_)
        ScribeOptimistic(initialAuthed, wat_)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title IChronicle
 *
 * @notice Interface for Chronicle Protocol's oracle products
 */
interface IChronicle {
    /// @notice Returns the oracle's identifier.
    /// @return wat The oracle's identifier.
    function wat() external view returns (bytes32 wat);

    /// @notice Returns the oracle's current value.
    /// @dev Reverts if no value set.
    /// @return value The oracle's current value.
    function read() external view returns (uint value);

    /// @notice Returns the oracle's current value and its age.
    /// @dev Reverts if no value set.
    /// @return value The oracle's current value.
    /// @return age The value's age.
    function readWithAge() external view returns (uint value, uint age);

    /// @notice Returns the oracle's current value.
    /// @return isValid True if value exists, false otherwise.
    /// @return value The oracle's current value if it exists, zero otherwise.
    function tryRead() external view returns (bool isValid, uint value);

    /// @notice Returns the oracle's current value and its age.
    /// @return isValid True if value exists, false otherwise.
    /// @return value The oracle's current value if it exists, zero otherwise.
    /// @return age The value's age if value exists, zero otherwise.
    function tryReadWithAge()
        external
        view
        returns (bool isValid, uint value, uint age);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IScribe} from "./IScribe.sol";

interface IScribeOptimistic is IScribe {
    /// @notice Thrown if attempted to opPoke while a previous opPoke is still
    ///         in challenge period.
    error InChallengePeriod();

    /// @notice Thrown if opChallenge called while no opPoke exists thats
    ///         challengeable.
    error NoOpPokeToChallenge();

    /// @notice Thrown if opChallenge called with SchnorrData not matching
    ///         opPoke's SchnorrData.
    /// @param gotHash The truncated keccak256 hash of the SchnorrData argument.
    /// @param wantHash The truncated expected keccak256 hash of the SchnorrData
    ///                 argument.
    error SchnorrDataMismatch(uint160 gotHash, uint160 wantHash);

    /// @notice Emitted when oracles was successfully opPoked.
    /// @param caller The caller's address.
    /// @param opFeed The feed that signed the opPoke.
    /// @param schnorrData The schnorrData opPoked.
    /// @param pokeData The pokeData opPoked.
    event OpPoked(
        address indexed caller,
        address indexed opFeed,
        IScribe.SchnorrData schnorrData,
        IScribe.PokeData pokeData
    );

    /// @notice Emitted when successfully challenged an opPoke.
    /// @param caller The caller's address.
    /// @param schnorrErr The abi-encoded custom error returned from the failed
    ///                   Schnorr signature verification.
    event OpPokeChallengedSuccessfully(
        address indexed caller, bytes schnorrErr
    );

    /// @notice Emitted when unsuccessfully challenged an opPoke.
    /// @param caller The caller's address.
    event OpPokeChallengedUnsuccessfully(address indexed caller);

    /// @notice Emitted when ETH reward paid for successfully challenging an
    ///         opPoke.
    /// @param challenger The challenger to which the reward was send.
    /// @param reward The ETH rewards paid.
    event OpChallengeRewardPaid(address indexed challenger, uint reward);

    /// @notice Emitted when an opPoke dropped.
    /// @dev opPoke's are dropped if security parameters are updated that could
    ///      lead to an initially valid opPoke becoming invalid or an opPoke was
    ///      was successfully challenged.
    /// @param caller The caller's address.
    /// @param pokeData The pokeData dropped.
    event OpPokeDataDropped(address indexed caller, IScribe.PokeData pokeData);

    /// @notice Emitted when length of opChallengePeriod updated.
    /// @param caller The caller's address.
    /// @param oldOpChallengePeriod The old opChallengePeriod's length.
    /// @param newOpChallengePeriod The new opChallengePeriod's length.
    event OpChallengePeriodUpdated(
        address indexed caller,
        uint16 oldOpChallengePeriod,
        uint16 newOpChallengePeriod
    );

    /// @notice Emitted when maxChallengeReward updated.
    /// @param caller The caller's address.
    /// @param oldMaxChallengeReward The old maxChallengeReward.
    /// @param newMaxChallengeReward The new maxChallengeReward.
    event MaxChallengeRewardUpdated(
        address indexed caller,
        uint oldMaxChallengeReward,
        uint newMaxChallengeReward
    );

    /// @notice Optimistically pokes the oracle.
    /// @dev Expects `pokeData`'s age to be greater than the timestamp of the
    ///      last successful poke.
    /// @dev Expects `ecdsaData` to be a signature from a feed.
    /// @dev Expects `ecdsaData` to prove the integrity of the `pokeData` and
    ///      `schnorrData`.
    /// @dev If the `schnorrData` is proven to be invalid via the opChallenge
    ///      function, the `ecdsaData` signing feed will be dropped.
    /// @param pokeData The PokeData being poked.
    /// @param schnorrData The SchnorrData optimistically assumed to be
    ///                    proving the `pokeData`'s integrity.
    /// @param ecdsaData The ECDSAData proving the integrity of the
    ///                  `pokeData` and `schnorrData`.
    function opPoke(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData,
        ECDSAData calldata ecdsaData
    ) external;

    /// @notice Challenges the current challengeable opPoke.
    /// @dev If opPoke is determined to be invalid, the caller receives an ETH
    ///      bounty. The bounty is defined via the `challengeReward()(uint)`
    ///      function.
    /// @dev If opPoke is determined to be invalid, the corresponding feed is
    ///      dropped.
    /// @param schnorrData The SchnorrData initially provided via
    ///                    opPoke.
    /// @return ok True if opPoke declared invalid, false otherwise.
    function opChallenge(SchnorrData calldata schnorrData)
        external
        returns (bool ok);

    /// @notice Returns the message expected to be signed via ECDSA for calling
    ///         opPoke.
    /// @dev The message is defined as:
    ///         H(tag ‖ H(wat ‖ pokeData ‖ schnorrData)), where H() is the keccak256 function.
    /// @param pokeData The pokeData being optimistically poked.
    /// @param schnorrData The schnorrData proving `pokeData`'s integrity.
    /// @return opPokeMessage Message to be signed for an opPoke for `pokeData`
    ///                       and `schnorrData`.
    function constructOpPokeMessage(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData
    ) external view returns (bytes32 opPokeMessage);

    /// @notice Returns the feed index of the feed last opPoke'd.
    /// @return opFeedIndex Feed index of the feed last opPoke'd.
    function opFeedIndex() external view returns (uint8 opFeedIndex);

    /// @notice Returns the opChallengePeriod security parameter.
    /// @return opChallengePeriod The opChallengePeriod security parameter.
    function opChallengePeriod()
        external
        view
        returns (uint16 opChallengePeriod);

    /// @notice Returns the maxChallengeRewards parameter.
    /// @return maxChallengeReward The maxChallengeReward parameter.
    function maxChallengeReward()
        external
        view
        returns (uint maxChallengeReward);

    /// @notice Returns the ETH rewards being paid for successfully challenging
    ///         an opPoke.
    /// @return challengeReward The ETH reward for successfully challenging an
    ///                         opPoke.
    function challengeReward() external view returns (uint challengeReward);

    /// @notice Updates the opChallengePeriod security parameter.
    /// @dev Only callable by auth'ed address.
    /// @dev Reverts if opChallengePeriod is zero.
    /// @dev Note that evaluating whether an opPoke is finalized happens via the
    ///      _current_ opChallengePeriod.
    ///      This means a finalized opPoke is dropped if opChallengePeriod is
    ///      decreased to a value less than opPoke's age.
    /// @param opChallengePeriod The value to update opChallengePeriod to.
    function setOpChallengePeriod(uint16 opChallengePeriod) external;

    /// @notice Updates the maxChallengeReward parameter.
    /// @dev Only callable by auth'ed address.
    /// @param maxChallengeReward The value to update maxChallengeReward to.
    function setMaxChallengeReward(uint maxChallengeReward) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IChronicle} from "chronicle-std/IChronicle.sol";

import {LibSecp256k1} from "./libs/LibSecp256k1.sol";

interface IScribe is IChronicle {
    /// @dev PokeData encapsulates a value and its age.
    struct PokeData {
        uint128 val;
        uint32 age;
    }

    /// @dev SchnorrData encapsulates a (aggregated) Schnorr signature.
    ///      Schnorr signatures are used to prove a PokeData's integrity.
    struct SchnorrData {
        bytes32 signature;
        address commitment;
        bytes signersBlob;
    }

    /// @dev ECDSAData encapsulates an ECDSA signature.
    struct ECDSAData {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Thrown if a poked value's age is not greater than the oracle's
    ///         current value's age.
    /// @param givenAge The poked value's age.
    /// @param currentAge The oracle's current value's age.
    error StaleMessage(uint32 givenAge, uint32 currentAge);

    /// @notice Thrown if a poked value's age is greater than the current
    ///         time.
    /// @param givenAge The poked value's age.
    /// @param currentTimestamp The current time.
    error FutureMessage(uint32 givenAge, uint32 currentTimestamp);

    /// @notice Thrown if Schnorr signature not signed by exactly bar many
    ///         signers.
    /// @param numberSigners The number of signers for given Schnorr signature.
    /// @param bar The bar security parameter.
    error BarNotReached(uint8 numberSigners, uint8 bar);

    /// @notice Thrown if signature signed by non-feed.
    /// @param signer The signer's address not being a feed.
    error SignerNotFeed(address signer);

    /// @notice Thrown if signer indexes are not encoded so that their
    ///         addresses are in ascending order.
    error SignersNotOrdered();

    /// @notice Thrown if Schnorr signature verification failed.
    error SchnorrSignatureInvalid();

    /// @notice Emitted when oracle was successfully poked.
    /// @param caller The caller's address.
    /// @param val The value poked.
    /// @param age The age of the value poked.
    event Poked(address indexed caller, uint128 val, uint32 age);

    /// @notice Emitted when new feed lifted.
    /// @param caller The caller's address.
    /// @param feed The feed address lifted.
    /// @param index The feed's index identifier.
    event FeedLifted(
        address indexed caller, address indexed feed, uint indexed index
    );

    /// @notice Emitted when feed dropped.
    /// @param caller The caller's address.
    /// @param feed The feed address dropped.
    /// @param index The feed's index identifier.
    event FeedDropped(
        address indexed caller, address indexed feed, uint indexed index
    );

    /// @notice Emitted when bar updated.
    /// @param caller The caller's address.
    /// @param oldBar The old bar's value.
    /// @param newBar The new bar's value.
    event BarUpdated(address indexed caller, uint8 oldBar, uint8 newBar);

    /// @notice Returns the feed registration message.
    /// @dev This message must be signed by a feed in order to be lifted.
    /// @return feedRegistrationMessage Chronicle Protocol's feed registration
    ///                                 message.
    function feedRegistrationMessage()
        external
        view
        returns (bytes32 feedRegistrationMessage);

    /// @notice The maximum number of feed lifts supported.
    /// @dev Note that the constraint comes from feed's indexes being encoded as
    ///      uint8 in SchnorrData.signersBlob.
    /// @return maxFeeds The maximum number of feed lifts supported.
    function maxFeeds() external view returns (uint maxFeeds);

    /// @notice Returns the bar security parameter.
    /// @return bar The bar security parameter.
    function bar() external view returns (uint8 bar);

    /// @notice Returns the number of decimals of the oracle's value.
    /// @dev Provides partial compatibility with Chainlink's
    ///      IAggregatorV3Interface.
    /// @return decimals The oracle value's number of decimals.
    function decimals() external view returns (uint8 decimals);

    /// @notice Returns the oracle's latest value.
    /// @dev Provides partial compatibility with Chainlink's
    ///      IAggregatorV3Interface.
    /// @return roundId 1.
    /// @return answer The oracle's latest value.
    /// @return startedAt 0.
    /// @return updatedAt The timestamp of oracle's latest update.
    /// @return answeredInRound 1.
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    /// @notice Pokes the oracle.
    /// @dev Expects `pokeData`'s age to be greater than the timestamp of the
    ///      last successful poke.
    /// @dev Expects `schnorrData` to prove `pokeData`'s integrity.
    ///      See `isAcceptableSchnorrSignatureNow(bytes32,SchnorrData)(bool)`.
    /// @param pokeData The PokeData being poked.
    /// @param schnorrData The SchnorrData proving the `pokeData`'s
    ///                    integrity.
    function poke(PokeData calldata pokeData, SchnorrData calldata schnorrData)
        external;

    /// @notice Returns whether the Schnorr signature `schnorrData` is
    ///         currently acceptable for message `message`.
    /// @dev Note that a valid Schnorr signature is only acceptable if the
    ///      signature was signed by exactly bar many feeds.
    ///      For more info, see `bar()(uint8)` and `feeds()(address[],uint[])`.
    /// @dev Note that bar and feeds are configurable, meaning a once acceptable
    ///      Schnorr signature may become unacceptable in the future.
    /// @param message The message expected to be signed via `schnorrData`.
    /// @param schnorrData The SchnorrData to verify whether it proves
    ///                    the `message`'s integrity.
    /// @return ok True if Schnorr signature is acceptable, false otherwise.
    function isAcceptableSchnorrSignatureNow(
        bytes32 message,
        SchnorrData calldata schnorrData
    ) external view returns (bool ok);

    /// @notice Returns the message expected to be signed via Schnorr for
    ///         `pokeData`.
    /// @dev The message is defined as:
    ///         H(tag ‖ H(wat ‖ pokeData)), where H() is the keccak256 function.
    /// @param pokeData The pokeData to create the message for.
    /// @return Message for `pokeData`.
    function constructPokeMessage(PokeData calldata pokeData)
        external
        view
        returns (bytes32);

    /// @notice Returns whether address `who` is a feed and its feed index
    ///         identifier.
    /// @param who The address to check.
    /// @return isFeed True if `who` is feed, false otherwise.
    /// @return feedIndex Non-zero if `who` is feed, zero otherwise.
    function feeds(address who)
        external
        view
        returns (bool isFeed, uint feedIndex);

    /// @notice Returns whether feedIndex `index` maps to a feed and, if so,
    ///         the feed's address.
    /// @param index The feedIndex to check.
    /// @return isFeed True if `index` maps to a feed, false otherwise.
    /// @return feed Address of the feed with feedIndex `index` if `index` maps
    ///              to feed, zero-address otherwise.
    function feeds(uint index)
        external
        view
        returns (bool isFeed, address feed);

    /// @notice Returns list of feed addresses and their index identifiers.
    /// @return feeds List of feed addresses.
    /// @return feedIndexes List of feed's indexes.
    function feeds()
        external
        view
        returns (address[] memory feeds, uint[] memory feedIndexes);

    /// @notice Lifts public key `pubKey` to being a feed.
    /// @dev Only callable by auth'ed address.
    /// @dev The message expected to be signed by `ecdsaData` is defined as via
    ///      `feedRegistrationMessage()(bytes32)` function.
    /// @param pubKey The public key of the feed.
    /// @param ecdsaData ECDSA signed message by the feed's public key.
    /// @return The feed index of the newly lifted feed.
    function lift(LibSecp256k1.Point memory pubKey, ECDSAData memory ecdsaData)
        external
        returns (uint);

    /// @notice Lifts public keys `pubKeys` to being feeds.
    /// @dev Only callable by auth'ed address.
    /// @dev The message expected to be signed by `ecdsaDatas` is defined as via
    ///      `feedRegistrationMessage()(bytes32)` function.
    /// @param pubKeys The public keys of the feeds.
    /// @param ecdsaDatas ECDSA signed message by the feeds' public keys.
    /// @return List of feed indexes of the newly lifted feeds.
    function lift(
        LibSecp256k1.Point[] memory pubKeys,
        ECDSAData[] memory ecdsaDatas
    ) external returns (uint[] memory);

    /// @notice Drops feed with index `feedIndex` from being a feed.
    /// @dev Only callable by auth'ed address.
    /// @param feedIndex The feed index identifier of the feed to drop.
    function drop(uint feedIndex) external;

    /// @notice Drops feeds with indexes `feedIndexes` from being feeds.
    /// @dev Only callable by auth'ed address.
    /// @param feedIndexes The feed's index identifiers of the feeds to drop.
    function drop(uint[] memory feedIndexes) external;

    /// @notice Updates the bar security parameters to `bar`.
    /// @dev Only callable by auth'ed address.
    /// @dev Reverts if `bar` is zero.
    /// @param bar The value to update bar to.
    function setBar(uint8 bar) external;

    /// @notice Returns the oracle's current value.
    /// @custom:deprecated Use `tryRead()(bool,uint)` instead.
    /// @return value The oracle's current value if it exists, zero otherwise.
    /// @return isValid True if value exists, false otherwise.
    function peek() external view returns (uint value, bool isValid);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IChronicle} from "chronicle-std/IChronicle.sol";
import {Auth} from "chronicle-std/auth/Auth.sol";
import {Toll} from "chronicle-std/toll/Toll.sol";

import {IScribe} from "./IScribe.sol";

import {LibSchnorr} from "./libs/LibSchnorr.sol";
import {LibSecp256k1} from "./libs/LibSecp256k1.sol";
import {LibSchnorrData} from "./libs/LibSchnorrData.sol";

/**
 * @title Scribe
 * @custom:version 1.0.0
 *
 * @notice Efficient Schnorr multi-signature based Oracle
 */
contract Scribe is IScribe, Auth, Toll {
    using LibSchnorr for LibSecp256k1.Point;
    using LibSecp256k1 for LibSecp256k1.Point;
    using LibSecp256k1 for LibSecp256k1.JacobianPoint;
    using LibSchnorrData for SchnorrData;

    /// @inheritdoc IScribe
    uint public constant maxFeeds = type(uint8).max - 1;

    /// @inheritdoc IScribe
    uint8 public constant decimals = 18;

    /// @inheritdoc IScribe
    bytes32 public constant feedRegistrationMessage = keccak256(
        abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256("Chronicle Feed Registration")
        )
    );

    /// @inheritdoc IChronicle
    bytes32 public immutable wat;

    /// @dev The storage slot of _pubKeys[0].
    uint internal immutable SLOT_pubKeys;

    // -- Storage --

    /// @dev Scribe's current value and corresponding age.
    PokeData internal _pokeData;

    /// @dev List of feeds' public keys.
    LibSecp256k1.Point[] internal _pubKeys;

    /// @dev Mapping of feeds' addresses to their public key indexes in
    ///      _pubKeys.
    mapping(address => uint) internal _feeds;

    /// @inheritdoc IScribe
    /// @dev Note to have as last in storage to enable downstream contracts to
    ///      pack the slot.
    uint8 public bar;

    // -- Constructor --

    constructor(address initialAuthed, bytes32 wat_) Auth(initialAuthed) {
        require(wat_ != 0);

        // Set wat immutable.
        wat = wat_;

        // Let initial bar be 2.
        _setBar(2);

        // Let _pubKeys[0] be the zero point.
        _pubKeys.push(LibSecp256k1.ZERO_POINT());

        // Let SLOT_pubKeys be _pubKeys[0].slot.
        uint pubKeysSlot;
        assembly ("memory-safe") {
            mstore(0x00, _pubKeys.slot)
            pubKeysSlot := keccak256(0x00, 0x20)
        }
        SLOT_pubKeys = pubKeysSlot;
    }

    // -- Poke Functionality --

    /// @dev Optimized function selector: 0x00000082.
    ///      Note that this function is _not_ defined via the IScribe interface
    ///      and one should _not_ depend on it.
    function poke_optimized_7136211(
        PokeData calldata pokeData,
        SchnorrData calldata schnorrData
    ) external {
        _poke(pokeData, schnorrData);
    }

    /// @inheritdoc IScribe
    function poke(PokeData calldata pokeData, SchnorrData calldata schnorrData)
        external
    {
        _poke(pokeData, schnorrData);
    }

    function _poke(PokeData calldata pokeData, SchnorrData calldata schnorrData)
        internal
        virtual
    {
        // Revert if pokeData stale.
        if (pokeData.age <= _pokeData.age) {
            revert StaleMessage(pokeData.age, _pokeData.age);
        }
        // Revert if pokeData from the future.
        if (pokeData.age > uint32(block.timestamp)) {
            revert FutureMessage(pokeData.age, uint32(block.timestamp));
        }

        // Revert if schnorrData does not prove integrity of pokeData.
        bool ok;
        bytes memory err;
        // forgefmt: disable-next-item
        (ok, err) = _verifySchnorrSignature(
            constructPokeMessage(pokeData),
            schnorrData
        );
        if (!ok) {
            _revert(err);
        }

        // Store pokeData's val in _pokeData storage and set its age to now.
        _pokeData.val = pokeData.val;
        _pokeData.age = uint32(block.timestamp);

        emit Poked(msg.sender, pokeData.val, pokeData.age);
    }

    /// @inheritdoc IScribe
    function constructPokeMessage(PokeData memory pokeData)
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(wat, pokeData.val, pokeData.age))
            )
        );
    }

    // -- Schnorr Signature Verification --

    /// @inheritdoc IScribe
    function isAcceptableSchnorrSignatureNow(
        bytes32 message,
        SchnorrData calldata schnorrData
    ) external view returns (bool) {
        bool ok;
        (ok, /*err*/ ) = _verifySchnorrSignature(message, schnorrData);

        return ok;
    }

    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Runtime is Θ(bar).
    function _verifySchnorrSignature(
        bytes32 message,
        SchnorrData calldata schnorrData
    ) internal view returns (bool, bytes memory) {
        // Let signerIndex be the current signer's index read from schnorrData.
        uint signerIndex;
        // Let signerPubKey be the public key stored for signerIndex.
        LibSecp256k1.Point memory signerPubKey;
        // Let signer be the address of signerPubKey.
        address signer;
        // Let lastSigner be the previous processed signer.
        address lastSigner;
        // Let aggPubKey be the sum of processed signers' public keys.
        // Note that Jacobian coordinates are used.
        LibSecp256k1.JacobianPoint memory aggPubKey;

        // Fail if number signers unequal to bar.
        //
        // Note that requiring equality constrains the verification's runtime
        // from Ω(bar) to Θ(bar).
        uint numberSigners = schnorrData.getSignerIndexLength();
        if (numberSigners != bar) {
            return (false, _errorBarNotReached(uint8(numberSigners), bar));
        }

        // Initiate signer variables with schnorrData's 0's signer index.
        signerIndex = schnorrData.getSignerIndex(0);
        signerPubKey = _unsafeLoadPubKeyAt(signerIndex);
        signer = signerPubKey.toAddress();

        // Fail if signer not feed.
        if (signerPubKey.isZeroPoint()) {
            return (false, _errorSignerNotFeed(signer));
        }

        // Initiate aggPubKey with value of first signerPubKey.
        aggPubKey = signerPubKey.toJacobian();

        // Aggregate remaining encoded signers.
        for (uint i = 1; i < bar;) {
            // Update Signer Variables.
            lastSigner = signer;
            signerIndex = schnorrData.getSignerIndex(i);
            signerPubKey = _unsafeLoadPubKeyAt(signerIndex);
            signer = signerPubKey.toAddress();

            // Fail if signer not feed.
            if (signerPubKey.isZeroPoint()) {
                return (false, _errorSignerNotFeed(signer));
            }

            // Fail if signers not strictly monotonically increasing.
            //
            // Note that this prevents double signing attacks and enforces
            // strict ordering.
            if (uint160(lastSigner) >= uint160(signer)) {
                return (false, _errorSignersNotOrdered());
            }

            // assert(aggPubKey.x != signerPubKey.x); // Indicates rogue-key attack

            // Add signerPubKey to already aggregated public keys.
            aggPubKey.addAffinePoint(signerPubKey);

            // forgefmt: disable-next-item
            unchecked { ++i; }
        }

        // Fail if signature verification fails.
        bool ok = aggPubKey.toAffine().verifySignature(
            message, schnorrData.signature, schnorrData.commitment
        );
        if (!ok) {
            return (false, _errorSchnorrSignatureInvalid());
        }

        // Otherwise Schnorr signature is valid.
        return (true, new bytes(0));
    }

    // -- Toll'ed Read Functionality --

    // - IChronicle Functions

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function read() external view virtual toll returns (uint) {
        uint val = _pokeData.val;
        require(val != 0);
        return val;
    }

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function tryRead() external view virtual toll returns (bool, uint) {
        uint val = _pokeData.val;
        return (val != 0, val);
    }

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function readWithAge() external view virtual toll returns (uint, uint) {
        uint val = _pokeData.val;
        uint age = _pokeData.age;
        require(val != 0);
        return (val, age);
    }

    /// @inheritdoc IChronicle
    /// @dev Only callable by toll'ed address.
    function tryReadWithAge()
        external
        view
        virtual
        toll
        returns (bool, uint, uint)
    {
        uint val = _pokeData.val;
        uint age = _pokeData.age;
        return (val != 0, val, age);
    }

    // - MakerDAO Compatibility

    /// @inheritdoc IScribe
    /// @dev Only callable by toll'ed address.
    function peek() external view virtual toll returns (uint, bool) {
        uint val = _pokeData.val;
        return (val, val != 0);
    }

    // - Chainlink Compatibility

    /// @inheritdoc IScribe
    /// @dev Only callable by toll'ed address.
    function latestRoundData()
        external
        view
        virtual
        toll
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        answer = int(uint(_pokeData.val));
        // assert(uint(answer) == uint(_pokeData.val));
        startedAt = 0;
        updatedAt = _pokeData.age;
        answeredInRound = roundId;
    }

    // -- Public Read Functionality --

    /// @inheritdoc IScribe
    function feeds(address who) external view returns (bool, uint) {
        uint index = _feeds[who];
        // assert(index != 0 ? !_pubKeys[index].isZeroPoint() : true);
        return (index != 0, index);
    }

    /// @inheritdoc IScribe
    function feeds(uint index) external view returns (bool, address) {
        if (index >= _pubKeys.length) {
            return (false, address(0));
        }

        LibSecp256k1.Point memory pubKey = _pubKeys[index];
        if (pubKey.isZeroPoint()) {
            return (false, address(0));
        }

        return (true, pubKey.toAddress());
    }

    /// @inheritdoc IScribe
    function feeds() external view returns (address[] memory, uint[] memory) {
        // Initiate arrays with upper limit length.
        uint upperLimitLength = _pubKeys.length;
        address[] memory feedsList = new address[](upperLimitLength);
        uint[] memory feedsIndexesList = new uint[](upperLimitLength);

        // Iterate over feeds' public keys. If a public key is non-zero, their
        // corresponding address is a feed.
        uint ctr;
        LibSecp256k1.Point memory pubKey;
        address feed;
        uint feedIndex;
        for (uint i; i < upperLimitLength;) {
            pubKey = _pubKeys[i];

            if (!pubKey.isZeroPoint()) {
                feed = pubKey.toAddress();
                // assert(feed != address(0));

                feedIndex = _feeds[feed];
                // assert(feedIndex != 0);

                feedsList[ctr] = feed;
                feedsIndexesList[ctr] = feedIndex;

                ctr++;
            }

            // forgefmt: disable-next-item
            unchecked { ++i; }
        }

        // Set length of arrays to number of feeds actually included.
        assembly ("memory-safe") {
            mstore(feedsList, ctr)
            mstore(feedsIndexesList, ctr)
        }

        return (feedsList, feedsIndexesList);
    }

    // -- Auth'ed Functionality --

    /// @inheritdoc IScribe
    function lift(LibSecp256k1.Point memory pubKey, ECDSAData memory ecdsaData)
        external
        auth
        returns (uint)
    {
        return _lift(pubKey, ecdsaData);
    }

    /// @inheritdoc IScribe
    function lift(
        LibSecp256k1.Point[] memory pubKeys,
        ECDSAData[] memory ecdsaDatas
    ) external auth returns (uint[] memory) {
        require(pubKeys.length == ecdsaDatas.length);

        uint[] memory indexes = new uint[](pubKeys.length);
        for (uint i; i < pubKeys.length;) {
            indexes[i] = _lift(pubKeys[i], ecdsaDatas[i]);

            // forgefmt: disable-next-item
            unchecked { ++i; }
        }

        // Note that indexes contains duplicates iff duplicate pubKeys provided.
        return indexes;
    }

    function _lift(LibSecp256k1.Point memory pubKey, ECDSAData memory ecdsaData)
        internal
        returns (uint)
    {
        address feed = pubKey.toAddress();
        // assert(feed != address(0));

        // forgefmt: disable-next-item
        address recovered = ecrecover(
            feedRegistrationMessage,
            ecdsaData.v,
            ecdsaData.r,
            ecdsaData.s
        );
        require(feed == recovered);

        uint index = _feeds[feed];
        if (index == 0) {
            _pubKeys.push(pubKey);
            index = _pubKeys.length - 1;
            _feeds[feed] = index;

            emit FeedLifted(msg.sender, feed, index);

            require(index <= maxFeeds);
        }

        return index;
    }

    /// @inheritdoc IScribe
    function drop(uint feedIndex) external auth {
        _drop(msg.sender, feedIndex);
    }

    /// @inheritdoc IScribe
    function drop(uint[] memory feedIndexes) external auth {
        for (uint i; i < feedIndexes.length;) {
            _drop(msg.sender, feedIndexes[i]);

            // forgefmt: disable-next-item
            unchecked { ++i; }
        }
    }

    function _drop(address caller, uint feedIndex) internal virtual {
        require(feedIndex < _pubKeys.length);
        address feed = _pubKeys[feedIndex].toAddress();

        if (_feeds[feed] != 0) {
            emit FeedDropped(caller, feed, _feeds[feed]);

            _feeds[feed] = 0;
            _pubKeys[feedIndex] = LibSecp256k1.ZERO_POINT();
        }
    }

    /// @inheritdoc IScribe
    function setBar(uint8 bar_) external auth {
        _setBar(bar_);
    }

    function _setBar(uint8 bar_) internal virtual {
        require(bar_ != 0);

        if (bar != bar_) {
            emit BarUpdated(msg.sender, bar, bar_);
            bar = bar_;
        }
    }

    // -- Internal Helpers --

    /// @dev Halts execution by reverting with `err`.
    function _revert(bytes memory err) internal pure {
        // assert(err.length != 0);
        assembly ("memory-safe") {
            let size := mload(err)
            let offset := add(err, 0x20)
            revert(offset, size)
        }
    }

    /// @dev Returns the public key at `_pubKeys[index]`, or zero point if
    ///      `index` out of bounds.
    function _unsafeLoadPubKeyAt(uint index)
        internal
        view
        returns (LibSecp256k1.Point memory)
    {
        // Push immutable to stack as accessing through assembly not supported.
        uint slotPubKeys = SLOT_pubKeys;

        LibSecp256k1.Point memory pubKey;
        assembly ("memory-safe") {
            // Note that a pubKey consists of two words.
            let realIndex := mul(index, 2)

            // Compute slot of _pubKeys[index].
            let slot := add(slotPubKeys, realIndex)

            // Load _pubKeys[index]'s coordinates to stack.
            let x := sload(slot)
            let y := sload(add(slot, 1))

            // Store coordinates in pubKey memory location.
            mstore(pubKey, x)
            mstore(add(pubKey, 0x20), y)
        }
        // assert(index < _pubKeys.length || pubKey.isZeroPoint());

        // Note that pubKey is zero if index out of bounds.
        return pubKey;
    }

    function _errorBarNotReached(uint8 got, uint8 want)
        internal
        pure
        returns (bytes memory)
    {
        // assert(got != want);
        return abi.encodeWithSelector(IScribe.BarNotReached.selector, got, want);
    }

    function _errorSignerNotFeed(address signer)
        internal
        pure
        returns (bytes memory)
    {
        // assert(_feeds[signer] == 0);
        return abi.encodeWithSelector(IScribe.SignerNotFeed.selector, signer);
    }

    function _errorSignersNotOrdered() internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IScribe.SignersNotOrdered.selector);
    }

    function _errorSchnorrSignatureInvalid()
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(IScribe.SchnorrSignatureInvalid.selector);
    }

    // -- Overridden Toll Functions --

    /// @dev Defines authorization for IToll's authenticated functions.
    function toll_auth() internal override(Toll) auth {}
}

/**
 * @dev Contract overwrite to deploy contract instances with specific naming.
 *
 *      For more info, see docs/Deployment.md.
 */
contract Chronicle_ETH_USD_smokes9 is Scribe {
    // @todo       ^^^^ ^^^^^ ^^^^^^^ Adjust name of Scribe instance.
    constructor(address initialAuthed, bytes32 wat_)
        Scribe(initialAuthed, wat_)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibSecp256k1} from "./LibSecp256k1.sol";

/**
 * @title LibSchnorr
 *
 * @notice Custom-purpose library for Schnorr signature verification on the
 *         secp256k1 curve
 */
library LibSchnorr {
    using LibSecp256k1 for LibSecp256k1.Point;

    /// @dev Returns whether `signature` and `commitment` sign via `pubKey`
    ///      message `message`.
    ///
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Uses constant amount of gas.
    function verifySignature(
        LibSecp256k1.Point memory pubKey,
        bytes32 message,
        bytes32 signature,
        address commitment
    ) internal pure returns (bool) {
        // Return false if signature or commitment is zero.
        if (signature == 0 || commitment == address(0)) {
            return false;
        }

        // Note to enforce pubKey is valid secp256k1 point.
        //
        // While the Scribe contract ensures to only verify signatures for valid
        // public keys, this check is enabled as an additional defense
        // mechanism.
        if (!pubKey.isOnCurve()) {
            return false;
        }

        // Note to enforce signature is less than Q to prevent signature
        // malleability.
        //
        // While the Scribe contract only accepts messages with strictly
        // monotonically increasing timestamps, circumventing replay attack
        // vectors and therefore also signature malleability issues at a higher
        // level, this check is enabled as an additional defense mechanism.
        if (uint(signature) >= LibSecp256k1.Q()) {
            return false;
        }

        // Construct challenge = H(Pₓ ‖ Pₚ ‖ m ‖ Rₑ) mod Q
        uint challenge = uint(
            keccak256(
                abi.encodePacked(
                    pubKey.x, uint8(pubKey.yParity()), message, commitment
                )
            )
        ) % LibSecp256k1.Q();

        // Compute msgHash = -sig * Pₓ      (mod Q)
        //                 = Q - (sig * Pₓ) (mod Q)
        //
        // Unchecked because the only protected operation performed is the
        // subtraction from Q where the subtrahend is the result of a (mod Q)
        // computation, i.e. the subtrahend is guaranteed to be less than Q.
        uint msgHash;
        unchecked {
            msgHash = LibSecp256k1.Q()
                - mulmod(uint(signature), pubKey.x, LibSecp256k1.Q());
        }

        // Compute v = Pₚ + 27
        //
        // Unchecked because pubKey.yParity() ∊ {0, 1} which cannot overflow
        // by adding 27.
        uint v;
        unchecked {
            v = pubKey.yParity() + 27;
        }

        // Set r = Pₓ
        uint r = pubKey.x;

        // Compute s = Q - (e * Pₓ) (mod Q)
        //
        // Unchecked because the only protected operation performed is the
        // subtraction from Q where the subtrahend is the result of a (mod Q)
        // computation, i.e. the subtrahend is guaranteed to be less than Q.
        uint s;
        unchecked {
            s = LibSecp256k1.Q() - mulmod(challenge, pubKey.x, LibSecp256k1.Q());
        }

        // Compute ([s]G - [e]P)ₑ via ecrecover.
        address recovered =
            ecrecover(bytes32(msgHash), uint8(v), bytes32(r), bytes32(s));

        // Verification succeeds iff ([s]G - [e]P)ₑ = Rₑ.
        //
        // Note that commitment is guaranteed to not be zero.
        return commitment == recovered;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibSecp256k1
 *
 * @notice Library for secp256k1 elliptic curve computations
 *
 * @dev This library was developed to efficiently compute aggregated public
 *      keys for Schnorr signatures based on secp256k1, i.e. it is _not_ a
 *      general purpose elliptic curve library!
 *
 *      References to the Ethereum Yellow Paper are based on the following
 *      version: "BERLIN VERSION beacfbd – 2022-10-24".
 */
library LibSecp256k1 {
    using LibSecp256k1 for LibSecp256k1.Point;
    using LibSecp256k1 for LibSecp256k1.JacobianPoint;

    uint private constant ADDRESS_MASK =
        0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // -- Secp256k1 Constants --
    //
    // Taken from https://www.secg.org/sec2-v2.pdf.
    // See section 2.4.1 "Recommended Parameters secp256k1".

    uint private constant _A = 0;
    uint private constant _B = 7;
    uint private constant _P =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    /// @dev Returns the order of the group.
    function Q() internal pure returns (uint) {
        return
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    }

    /// @dev Returns the generator G.
    ///      Note that the generator is also called base point.
    function G() internal pure returns (Point memory) {
        return Point({
            x: 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            y: 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
        });
    }

    /// @dev Returns the zero point.
    function ZERO_POINT() internal pure returns (Point memory) {
        return Point({x: 0, y: 0});
    }

    // -- (Affine) Point --

    /// @dev Point encapsulates a secp256k1 point in Affine coordinates.
    struct Point {
        uint x;
        uint y;
    }

    /// @dev Returns the Ethereum address of `self`.
    ///
    /// @dev An Ethereum address is defined as the rightmost 160 bits of the
    ///      keccak256 hash of the concatenation of the hex-encoded x and y
    ///      coordinates of the corresponding ECDSA public key.
    ///      See "Appendix F: Signing Transactions" §134 in the Yellow Paper.
    function toAddress(Point memory self) internal pure returns (address) {
        address addr;
        // Functionally equivalent Solidity code:
        // addr = address(uint160(uint(keccak256(abi.encode(self.x, self.y)))));
        assembly ("memory-safe") {
            addr := and(keccak256(self, 0x40), ADDRESS_MASK)
        }
        return addr;
    }

    /// @dev Returns Affine point `self` in Jacobian coordinates.
    function toJacobian(Point memory self)
        internal
        pure
        returns (JacobianPoint memory)
    {
        return JacobianPoint({x: self.x, y: self.y, z: 1});
    }

    /// @dev Returns whether `self` is the zero point.
    function isZeroPoint(Point memory self) internal pure returns (bool) {
        return (self.x | self.y) == 0;
    }

    /// @dev Returns whether `self` is a point on the curve.
    ///
    /// @dev The secp256k1 curve is specified as y² ≡ x³ + ax + b (mod P)
    ///      where:
    ///         a = 0
    ///         b = 7
    function isOnCurve(Point memory self) internal pure returns (bool) {
        uint left = mulmod(self.y, self.y, _P);
        // Note that adding a * x can be waived as ∀x: a * x = 0.
        uint right =
            addmod(mulmod(self.x, mulmod(self.x, self.x, _P), _P), _B, _P);

        return left == right;
    }

    /// @dev Returns the parity of `self`'s y coordinate.
    ///
    /// @dev The value 0 represents an even y value and 1 represents an odd y
    ///      value.
    ///      See "Appendix F: Signing Transactions" in the Yellow Paper.
    function yParity(Point memory self) internal pure returns (uint) {
        return self.y & 1;
    }

    // -- Jacobian Point --

    /// @dev JacobianPoint encapsulates a secp256k1 point in Jacobian
    ///      coordinates.
    struct JacobianPoint {
        uint x;
        uint y;
        uint z;
    }

    /// @dev Returns Jacobian point `self` in Affine coordinates.
    ///
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Does not run into an infinite loop.
    function toAffine(JacobianPoint memory self)
        internal
        pure
        returns (Point memory)
    {
        Point memory result;

        // Compute z⁻¹, i.e. the modular inverse of self.z.
        uint zInv = _invMod(self.z);

        // Compute (z⁻¹)² (mod P)
        uint zInv_2 = mulmod(zInv, zInv, _P);

        // Compute self.x * (z⁻¹)² (mod P), i.e. the x coordinate of given
        // Jacobian point in Affine representation.
        result.x = mulmod(self.x, zInv_2, _P);

        // Compute self.y * (z⁻¹)³ (mod P), i.e. the y coordinate of given
        // Jacobian point in Affine representation.
        result.y = mulmod(self.y, mulmod(zInv, zInv_2, _P), _P);

        return result;
    }

    /// @dev Adds Affine point `p` to Jacobian point `self`.
    ///
    ///      It is the caller's responsibility to ensure given points are on the
    ///      curve!
    ///
    ///      Computation based on: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-madd-2007-bl.
    ///
    ///      Note that the formula assumes z2 = 1, which always holds if z2's
    ///      point is given in Affine coordinates.
    ///
    ///      Note that eventhough the function is marked as pure, to be
    ///      understood as only being dependent on the input arguments, it
    ///      nevertheless has side effects by writing the result into the
    ///      `self` memory variable.
    ///
    /// @custom:invariant Only mutates `self` memory variable.
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Uses constant amount of gas.
    function addAffinePoint(JacobianPoint memory self, Point memory p)
        internal
        pure
    {
        // Addition formula:
        //      x = r² - j - (2 * v)             (mod P)
        //      y = (r * (v - x)) - (2 * y1 * j) (mod P)
        //      z = (z1 + h)² - z1² - h²         (mod P)
        //
        // where:
        //      r = 2 * (s - y1) (mod P)
        //      j = h * i        (mod P)
        //      v = x1 * i       (mod P)
        //      h = u - x1       (mod P)
        //      s = y2 * z1³     (mod P)       Called s2 in reference
        //      i = 4 * h²       (mod P)
        //      u = x2 * z1²     (mod P)       Called u2 in reference
        //
        // and:
        //      x1 = self.x
        //      y1 = self.y
        //      z1 = self.z
        //      x2 = p.x
        //      y2 = p.y
        //
        // Note that in order to save memory allocations the result is stored
        // in the self variable, i.e. the following holds true after the
        // functions execution:
        //      x = self.x
        //      y = self.y
        //      z = self.z

        // Cache self's coordinates on stack.
        uint x1 = self.x;
        uint y1 = self.y;
        uint z1 = self.z;

        // Compute z1_2 = z1²     (mod P)
        //              = z1 * z1 (mod P)
        uint z1_2 = mulmod(z1, z1, _P);

        // Compute h = u        - x1       (mod P)
        //           = u        + (P - x1) (mod P)
        //           = x2 * z1² + (P - x1) (mod P)
        //
        // Unchecked because the only protected operation performed is P - x1
        // where x1 is guaranteed by the caller to be an x coordinate belonging
        // to a point on the curve, i.e. being less than P.
        uint h;
        unchecked {
            h = addmod(mulmod(p.x, z1_2, _P), _P - x1, _P);
        }

        // Compute h_2 = h²    (mod P)
        //             = h * h (mod P)
        uint h_2 = mulmod(h, h, _P);

        // Compute i = 4 * h² (mod P)
        uint i = mulmod(4, h_2, _P);

        // Compute z = (z1 + h)² - z1²       - h²       (mod P)
        //           = (z1 + h)² - z1²       + (P - h²) (mod P)
        //           = (z1 + h)² + (P - z1²) + (P - h²) (mod P)
        //             ╰───────╯   ╰───────╯   ╰──────╯
        //               left         mid       right
        //
        // Unchecked because the only protected operations performed are
        // subtractions from P where the subtrahend is the result of a (mod P)
        // computation, i.e. the subtrahend being guaranteed to be less than P.
        unchecked {
            uint left = mulmod(addmod(z1, h, _P), addmod(z1, h, _P), _P);
            uint mid = _P - z1_2;
            uint right = _P - h_2;

            self.z = addmod(left, addmod(mid, right, _P), _P);
        }

        // Compute v = x1 * i (mod P)
        uint v = mulmod(x1, i, _P);

        // Compute j = h * i (mod P)
        uint j = mulmod(h, i, _P);

        // Compute r = 2 * (s               - y1)       (mod P)
        //           = 2 * (s               + (P - y1)) (mod P)
        //           = 2 * ((y2 * z1³)      + (P - y1)) (mod P)
        //           = 2 * ((y2 * z1² * z1) + (P - y1)) (mod P)
        //
        // Unchecked because the only protected operation performed is P - y1
        // where y1 is guaranteed by the caller to be an y coordinate belonging
        // to a point on the curve, i.e. being less than P.
        uint r;
        unchecked {
            r = mulmod(
                2,
                addmod(mulmod(p.y, mulmod(z1_2, z1, _P), _P), _P - y1, _P),
                _P
            );
        }

        // Compute x = r² - j - (2 * v)             (mod P)
        //           = r² - j + (P - (2 * v))       (mod P)
        //           = r² + (P - j) + (P - (2 * v)) (mod P)
        //                  ╰─────╯   ╰───────────╯
        //                    mid         right
        //
        // Unchecked because the only protected operations performed are
        // subtractions from P where the subtrahend is the result of a (mod P)
        // computation, i.e. the subtrahend being guaranteed to be less than P.
        unchecked {
            uint r_2 = mulmod(r, r, _P);
            uint mid = _P - j;
            uint right = _P - mulmod(2, v, _P);

            self.x = addmod(r_2, addmod(mid, right, _P), _P);
        }

        // Compute y = (r * (v - x))       - (2 * y1 * j)       (mod P)
        //           = (r * (v - x))       + (P - (2 * y1 * j)) (mod P)
        //           = (r * (v + (P - x))) + (P - (2 * y1 * j)) (mod P)
        //             ╰─────────────────╯   ╰────────────────╯
        //                    left                 right
        //
        // Unchecked because the only protected operations performed are
        // subtractions from P where the subtrahend is the result of a (mod P)
        // computation, i.e. the subtrahend being guaranteed to be less than P.
        unchecked {
            uint left = mulmod(r, addmod(v, _P - self.x, _P), _P);
            uint right = _P - mulmod(2, mulmod(y1, j, _P), _P);

            self.y = addmod(left, right, _P);
        }
    }

    // -- Private Helpers --

    /// @dev Returns the modular inverse of `x` for modulo `_P`.
    ///
    ///      It is the caller's responsibility to ensure `x` is less than `_P`!
    ///
    ///      The modular inverse of `x` is x⁻¹ such that x * x⁻¹ ≡ 1 (mod P).
    ///
    /// @dev Modified from Jordi Baylina's [ecsol](https://github.com/jbaylina/ecsol/blob/c2256afad126b7500e6f879a9369b100e47d435d/ec.sol#L51-L67).
    ///
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Does not run into an infinite loop.
    function _invMod(uint x) private pure returns (uint) {
        uint t;
        uint q;
        uint newT = 1;
        uint r = _P;

        assembly ("memory-safe") {
            // Implemented in assembly to circumvent division-by-zero
            // and over-/underflow protection.
            //
            // Functionally equivalent Solidity code:
            //      while (x != 0) {
            //          q = r / x;
            //          (t, newT) = (newT, addmod(t, (_P - mulmod(q, newT, _P)), _P));
            //          (r, x) = (x, r - (q * x));
            //      }
            //
            // For the division r / x, x is guaranteed to not be zero via the
            // loop condition.
            //
            // The subtraction of form P - mulmod(_, _, P) is guaranteed to not
            // underflow due to the subtrahend being a (mod P) result,
            // i.e. the subtrahend being guaranteed to be less than P.
            //
            // The subterm q * x is guaranteed to not overflow because
            // q * x ≤ r due to q = ⎣r / x⎦.
            //
            // The term r - (q * x) is guaranteed to not underflow because
            // q * x ≤ r and therefore r - (q * x) ≥ 0.
            for {} x {} {
                q := div(r, x)

                let tmp := t
                t := newT
                newT := addmod(tmp, sub(_P, mulmod(q, newT, _P)), _P)

                tmp := r
                r := x
                x := sub(tmp, mul(q, x))
            }
        }

        return t;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAuth} from "./IAuth.sol";

/**
 * @title Auth Module
 *
 * @dev The `Auth` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said to be _auth'ed_.
 *
 *      Initially, the address given as constructor argument is the only address
 *      auth'ed. Through the `rely(address)` and `deny(address)` functions,
 *      auth'ed callers are able to grant/renounce auth to/from addresses.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `auth`, which can be applied to functions to restrict their
 *      use to only auth'ed callers.
 */
abstract contract Auth is IAuth {
    /// @dev Mapping storing whether address is auth'ed.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _wards[x] ∊ {0, 1}
    /// @custom:invariant Only address given as constructor argument is authenticated after deployment.
    ///                     deploy(initialAuthed) → (∀x ∊ Address: _wards[x] == 1 → x == initialAuthed)
    /// @custom:invariant Only functions `rely` and `deny` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x])
    ///                                     → (msg.sig == "rely" ∨ msg.sig == "deny")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x]) → _wards[msg.sender] = 1
    mapping(address => uint) private _wards;

    /// @dev List of addresses possibly being auth'ed.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being auth'ed anymore.
    /// @custom:invariant Every address being auth'ed once is element of the list.
    ///                     ∀x ∊ Address: authed(x) -> x ∊ _wardsTouched
    address[] private _wardsTouched;

    /// @dev Ensures caller is auth'ed.
    modifier auth() {
        assembly ("memory-safe") {
            // Compute slot of _wards[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _wards.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not auth'ed.
            let isAuthed := sload(slot)
            if iszero(isAuthed) {
                // Store selector of `NotAuthorized(address)`.
                mstore(0x00, 0x4a0bfec1)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    constructor(address initialAuthed) {
        _wards[initialAuthed] = 1;
        _wardsTouched.push(initialAuthed);

        // Note to use address(0) as caller to indicate address was auth'ed
        // during deployment.
        emit AuthGranted(address(0), initialAuthed);
    }

    /// @inheritdoc IAuth
    function rely(address who) external auth {
        if (_wards[who] == 1) return;

        _wards[who] = 1;
        _wardsTouched.push(who);
        emit AuthGranted(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function deny(address who) external auth {
        if (_wards[who] == 0) return;

        _wards[who] = 0;
        emit AuthRenounced(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function authed(address who) public view returns (bool) {
        return _wards[who] == 1;
    }

    /// @inheritdoc IAuth
    /// @custom:invariant Only contains auth'ed addresses.
    ///                     ∀x ∊ authed(): _wards[x] == 1
    /// @custom:invariant Contains all auth'ed addresses.
    ///                     ∀x ∊ Address: _wards[x] == 1 → x ∊ authed()
    function authed() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory wardsList = new address[](_wardsTouched.length);

        // Iterate through all possible auth'ed addresses.
        uint ctr;
        for (uint i; i < wardsList.length; i++) {
            // Add address only if still auth'ed.
            if (_wards[_wardsTouched[i]] == 1) {
                wardsList[ctr++] = _wardsTouched[i];
            }
        }

        // Set length of array to number of auth'ed addresses actually included.
        assembly ("memory-safe") {
            mstore(wardsList, ctr)
        }

        return wardsList;
    }

    /// @inheritdoc IAuth
    function wards(address who) public view returns (uint) {
        return _wards[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IToll} from "./IToll.sol";

/**
 * @title Toll Module
 *
 * @notice "Toll paid, we kiss - but dissension looms, maybe diss?"
 *
 * @dev The `Toll` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said the be _tolled_.
 *
 *      Initially, no address is tolled. Through the `kiss(address)` and
 *      `diss(address)` functions, auth'ed callers are able to toll/de-toll
 *      addresses. Authentication for these functions is defined via the
 *      downstream implemented `toll_auth()` function.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `toll`, which can be applied to functions to restrict their
 *      use to only tolled callers.
 */
abstract contract Toll is IToll {
    /// @dev Mapping storing whether address is tolled.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _buds[x] ∊ {0, 1}
    /// @custom:invariant Only functions `kiss` and `diss` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → (msg.sig == "kiss" ∨ msg.sig == "diss")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → toll_auth()
    mapping(address => uint) private _buds;

    /// @dev List of addresses possibly being tolled.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being tolled anymore.
    /// @custom:invariant Every address being tolled once is element of the list.
    ///                     ∀x ∊ Address: tolled(x) → x ∊ _budsTouched
    address[] private _budsTouched;

    /// @dev Ensures caller is tolled.
    modifier toll() {
        assembly ("memory-safe") {
            // Compute slot of _buds[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _buds.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not tolled.
            let isTolled := sload(slot)
            if iszero(isTolled) {
                // Store selector of `NotTolled(address)`.
                mstore(0x00, 0xd957b595)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    /// @dev Reverts if caller not allowed to access protected function.
    /// @dev Must be implemented in downstream contract.
    function toll_auth() internal virtual;

    /// @inheritdoc IToll
    function kiss(address who) external {
        toll_auth();

        if (_buds[who] == 1) return;

        _buds[who] = 1;
        _budsTouched.push(who);
        emit TollGranted(msg.sender, who);
    }

    /// @inheritdoc IToll
    function diss(address who) external {
        toll_auth();

        if (_buds[who] == 0) return;

        _buds[who] = 0;
        emit TollRenounced(msg.sender, who);
    }

    /// @inheritdoc IToll
    function tolled(address who) public view returns (bool) {
        return _buds[who] == 1;
    }

    /// @inheritdoc IToll
    /// @custom:invariant Only contains tolled addresses.
    ///                     ∀x ∊ tolled(): _tolled[x]
    /// @custom:invariant Contains all tolled addresses.
    ///                     ∀x ∊ Address: _tolled[x] == 1 → x ∊ tolled()
    function tolled() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory budsList = new address[](_budsTouched.length);

        // Iterate through all possible tolled addresses.
        uint ctr;
        for (uint i; i < budsList.length; i++) {
            // Add address only if still tolled.
            if (_buds[_budsTouched[i]] == 1) {
                budsList[ctr++] = _budsTouched[i];
            }
        }

        // Set length of array to number of tolled addresses actually included.
        assembly ("memory-safe") {
            mstore(budsList, ctr)
        }

        return budsList;
    }

    /// @inheritdoc IToll
    function bud(address who) public view returns (uint) {
        return _buds[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IScribe} from "../IScribe.sol";

import {LibBytes} from "./LibBytes.sol";

/**
 * @title LibSchnorrData
 *
 * @notice Library for working with IScribe.SchnorrData
 */
library LibSchnorrData {
    using LibBytes for uint;

    /// @dev Size of a word is 32 bytes, i.e. 256 bits.
    uint private constant WORD_SIZE = 32;

    /// @dev Returns the signer index from schnorrData.signersBlob with index
    ///      `index`.
    ///
    /// @dev Note that schnorrData.signersBlob is big-endian encoded and
    ///      counting starts at the highest order byte, i.e. the signer index 0
    ///      is the highest order byte of schnorrData.signersBlob.
    ///
    /// @custom:example SignersBlob encoding via Solidity:
    ///
    ///      ```solidity
    ///      bytes memory signersBlob;
    ///      uint8[] memory indexes = someFuncReturningUint8Array();
    ///      for (uint i; i < indexes.length; i++) {
    ///          signersBlob = abi.encodePacked(signersBlob, indexes[i]);
    ///      }
    ///      ```
    ///
    /// @dev Calldata layout for `schnorrData`:
    ///
    ///      [schnorrData]        signature             -> schnorrData.signature
    ///      [schnorrData + 0x20] commitment            -> schnorrData.commitment
    ///      [schnorrData + 0x40] offset(signersBlob)
    ///      [schnorrData + 0x60] len(signersBlob)      -> schnorrData.signersBlob.length
    ///      [schnorrData + 0x80] signersBlob[0]        -> schnorrData.signersBlob[0]
    ///      ...
    ///
    ///      Note that the `schnorrData` variable holds the offset to the
    ///      `schnorrData` struct:
    ///
    ///      ```solidity
    ///      bytes32 signature;
    ///      assembly {
    ///         signature := calldataload(schnorrData)
    ///      }
    ///      assert(signature == schnorrData.signature)
    ///      ```
    ///
    ///      Note that `offset(signersBlob)` is the offset to `signersBlob[0]`
    ///      from the index `offset(signersBlob)`.
    ///
    /// @custom:invariant Reverts iff out of gas.
    function getSignerIndex(
        IScribe.SchnorrData calldata schnorrData,
        uint index
    ) internal pure returns (uint) {
        uint word;
        assembly ("memory-safe") {
            let wordIndex := mul(div(index, WORD_SIZE), WORD_SIZE)

            // Calldata index for schnorrData.signersBlob[0] is schnorrData's
            // offset plus 4 words, i.e. 0x80.
            let start := add(schnorrData, 0x80)

            // Note that reading non-existing calldata returns zero.
            // Note that overflow is no concern because index's upper limit is
            // bounded by bar, which is of type uint8.
            word := calldataload(add(start, wordIndex))
        }

        // Unchecked because the subtrahend is guaranteed to be less than or
        // equal to 31 due to being a (mod 32) result.
        uint byteIndex;
        unchecked {
            byteIndex = 31 - (index % WORD_SIZE);
        }

        return word.getByteAtIndex(byteIndex);
    }

    /// @dev Returns the number of signers encoded in schnorrData.signersBlob.
    function getSignerIndexLength(IScribe.SchnorrData calldata schnorrData)
        internal
        pure
        returns (uint)
    {
        uint index;
        assembly ("memory-safe") {
            // Calldata index for schnorrData.signersBlob.length is
            // schnorrData's offset plus 3 words, i.e. 0x60.
            index := calldataload(add(schnorrData, 0x60))
        }
        return index;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAuth {
    /// @notice Thrown by protected function if caller not auth'ed.
    /// @param caller The caller's address.
    error NotAuthorized(address caller);

    /// @notice Emitted when auth granted to address.
    /// @param caller The caller's address.
    /// @param who The address auth got granted to.
    event AuthGranted(address indexed caller, address indexed who);

    /// @notice Emitted when auth renounced from address.
    /// @param caller The caller's address.
    /// @param who The address auth got renounced from.
    event AuthRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant auth.
    function rely(address who) external;

    /// @notice Renounces address `who`'s auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce auth.
    function deny(address who) external;

    /// @notice Returns whether address `who` is auth'ed.
    /// @param who The address to check.
    /// @return True if `who` is auth'ed, false otherwise.
    function authed(address who) external view returns (bool);

    /// @notice Returns full list of addresses granted auth.
    /// @dev May contain duplicates.
    /// @return List of addresses granted auth.
    function authed() external view returns (address[] memory);

    /// @notice Returns whether address `who` is auth'ed.
    /// @custom:deprecated Use `authed(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is auth'ed, 0 otherwise.
    function wards(address who) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IToll {
    /// @notice Thrown by protected function if caller not tolled.
    /// @param caller The caller's address.
    error NotTolled(address caller);

    /// @notice Emitted when toll granted to address.
    /// @param caller The caller's address.
    /// @param who The address toll got granted to.
    event TollGranted(address indexed caller, address indexed who);

    /// @notice Emitted when toll renounced from address.
    /// @param caller The caller's address.
    /// @param who The address toll got renounced from.
    event TollRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant toll.
    function kiss(address who) external;

    /// @notice Renounces address `who`'s toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce toll.
    function diss(address who) external;

    /// @notice Returns whether address `who` is tolled.
    /// @param who The address to check.
    /// @return True if `who` is tolled, false otherwise.
    function tolled(address who) external view returns (bool);

    /// @notice Returns full list of addresses tolled.
    /// @dev May contain duplicates.
    /// @return List of addresses tolled.
    function tolled() external view returns (address[] memory);

    /// @notice Returns whether address `who` is tolled.
    /// @custom:deprecated Use `tolled(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is tolled, 0 otherwise.
    function bud(address who) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibBytes
 *
 * @notice Library for common byte operations
 */
library LibBytes {
    /// @dev Returns the `index`'s byte from `word`.
    ///
    ///      It is the caller's responsibility to ensure `index < 32`!
    ///
    /// @custom:invariant Uses constant amount of gas.
    function getByteAtIndex(uint word, uint index)
        internal
        pure
        returns (uint)
    {
        uint result;
        assembly ("memory-safe") {
            result := byte(sub(31, index), word)
        }

        // Note that the resulting byte is returned as word.
        return result;
    }
}