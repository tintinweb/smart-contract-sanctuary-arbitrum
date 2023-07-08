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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC6381
 * @author RMRK team
 * @notice Interface smart contract of the RMRK emote tracker module.
 */
interface IERC6381 is IERC165 {
    /**
     * @notice Used to notify listeners that the token with the specified ID has been emoted to or that the reaction has been revoked.
     * @dev The event MUST only be emitted if the state of the emote is changed.
     * @param emoter Address of the account that emoted or revoked the reaction to the token
     * @param collection Address of the collection smart contract containing the token being emoted to or having the reaction revoked
     * @param tokenId ID of the token
     * @param emoji Unicode identifier of the emoji
     * @param on Boolean value signifying whether the token was emoted to (`true`) or if the reaction has been revoked (`false`)
     */
    event Emoted(
        address indexed emoter,
        address indexed collection,
        uint256 indexed tokenId,
        bytes4 emoji,
        bool on
    );

    /**
     * @notice Used to get the number of emotes for a specific emoji on a token.
     * @param collection Address of the collection containing the token being checked for emoji count
     * @param tokenId ID of the token to check for emoji count
     * @param emoji Unicode identifier of the emoji
     * @return Number of emotes with the emoji on the token
     */
    function emoteCountOf(
        address collection,
        uint256 tokenId,
        bytes4 emoji
    ) external view returns (uint256);

    /**
     * @notice Used to get the number of emotes for a specific emoji on a set of tokens.
     * @param collections An array of addresses of the collections containing the tokens being checked for emoji count
     * @param tokenIds An array of IDs of the tokens to check for emoji count
     * @param emojis An array of unicode identifiers of the emojis
     * @return An array of numbers of emotes with the emoji on the tokens
     */
    function bulkEmoteCountOf(
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis
    ) external view returns (uint256[] memory);

    /**
     * @notice Used to get the information on whether the specified address has used a specific emoji on a specific
     *  token.
     * @param emoter Address of the account we are checking for a reaction to a token
     * @param collection Address of the collection smart contract containing the token being checked for emoji reaction
     * @param tokenId ID of the token being checked for emoji reaction
     * @param emoji The ASCII emoji code being checked for reaction
     * @return A boolean value indicating whether the `emoter` has used the `emoji` on the token (`true`) or not
     *  (`false`)
     */
    function hasEmoterUsedEmote(
        address emoter,
        address collection,
        uint256 tokenId,
        bytes4 emoji
    ) external view returns (bool);

    /**
     * @notice Used to get the information on whether the specified addresses have used specific emojis on specific
     *  tokens.
     * @param emoters An array of addresses of the accounts we are checking for reactions to tokens
     * @param collections An array of addresses of the collection smart contracts containing the tokens being checked
     *  for emoji reactions
     * @param tokenIds An array of IDs of the tokens being checked for emoji reactions
     * @param emojis An array of the ASCII emoji codes being checked for reactions
     * @return An array of boolean values indicating whether the `emoter`s has used the `emoji`s on the tokens (`true`)
     *  or not (`false`)
     */
    function haveEmotersUsedEmotes(
        address[] memory emoters,
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis
    ) external view returns (bool[] memory);

    /**
     * @notice Used to get the message to be signed by the `emoter` in order for the reaction to be submitted by someone
     *  else.
     * @param collection The address of the collection smart contract containing the token being emoted at
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     * @param deadline UNIX timestamp of the deadline for the signature to be submitted
     * @return The message to be signed by the `emoter` in order for the reaction to be submitted by someone else
     */
    function prepareMessageToPresignEmote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state,
        uint256 deadline
    ) external view returns (bytes32);

    /**
     * @notice Used to get multiple messages to be signed by the `emoter` in order for the reaction to be submitted by someone
     *  else.
     * @param collections An array of addresses of the collection smart contracts containing the tokens being emoted at
     * @param tokenIds An array of IDs of the tokens being emoted
     * @param emojis An arrau of unicode identifiers of the emojis
     * @param states An array of boolean values signifying whether to emote (`true`) or undo (`false`) emote
     * @param deadlines An array of UNIX timestamps of the deadlines for the signatures to be submitted
     * @return The array of messages to be signed by the `emoter` in order for the reaction to be submitted by someone else
     */
    function bulkPrepareMessagesToPresignEmote(
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis,
        bool[] memory states,
        uint256[] memory deadlines
    ) external view returns (bytes32[] memory);

    /**
     * @notice Used to emote or undo an emote on a token.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @param collection Address of the collection containing the token being emoted at
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     */
    function emote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) external;

    /**
     * @notice Used to emote or undo an emote on multiple tokens.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @dev MUST revert if the lengths of the `collections`, `tokenIds`, `emojis` and `states` arrays are not equal.
     * @param collections An array of addresses of the collections containing the tokens being emoted at
     * @param tokenIds An array of IDs of the tokens being emoted
     * @param emojis An array of unicode identifiers of the emojis
     * @param states An array of boolean values signifying whether to emote (`true`) or undo (`false`) emote
     */
    function bulkEmote(
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis,
        bool[] memory states
    ) external;

    /**
     * @notice Used to emote or undo an emote on someone else's behalf.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @dev MUST revert if the lengths of the `collections`, `tokenIds`, `emojis` and `states` arrays are not equal.
     * @dev MUST revert if the `deadline` has passed.
     * @dev MUST revert if the recovered address is the zero address.
     * @param emoter The address that presigned the emote
     * @param collection The address of the collection smart contract containing the token being emoted at
     * @param tokenId IDs of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     * @param deadline UNIX timestamp of the deadline for the signature to be submitted
     * @param v `v` value of an ECDSA signature of the message obtained via `prepareMessageToPresignEmote`
     * @param r `r` value of an ECDSA signature of the message obtained via `prepareMessageToPresignEmote`
     * @param s `s` value of an ECDSA signature of the message obtained via `prepareMessageToPresignEmote`
     */
    function presignedEmote(
        address emoter,
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Used to bulk emote or undo an emote on someone else's behalf.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @dev MUST revert if the lengths of the `collections`, `tokenIds`, `emojis` and `states` arrays are not equal.
     * @dev MUST revert if the `deadline` has passed.
     * @dev MUST revert if the recovered address is the zero address.
     * @param emoters An array of addresses of the accounts that presigned the emotes
     * @param collections An array of addresses of the collections containing the tokens being emoted at
     * @param tokenIds An array of IDs of the tokens being emoted
     * @param emojis An array of unicode identifiers of the emojis
     * @param states An array of boolean values signifying whether to emote (`true`) or undo (`false`) emote
     * @param deadlines UNIX timestamp of the deadline for the signature to be submitted
     * @param v An array of `v` values of an ECDSA signatures of the messages obtained via `prepareMessageToPresignEmote`
     * @param r An array of `r` values of an ECDSA signatures of the messages obtained via `prepareMessageToPresignEmote`
     * @param s An array of `s` values of an ECDSA signatures of the messages obtained via `prepareMessageToPresignEmote`
     */
    function bulkPresignedEmote(
        address[] memory emoters,
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis,
        bool[] memory states,
        uint256[] memory deadlines,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@rmrk-team/evm-contracts/contracts/RMRK/extension/emotable/IERC6381.sol";

error BulkParametersOfUnequalLength();
error ExpiredPresignedEmote();
error InvalidSignature();

/**
 * @title EmoteRepository
 * @author RMRK team
 * @notice The user interface is available @ https://emotes.app/.
 */
contract EmoteRepository is IERC6381 {
    bytes32 public immutable DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                "ERC-6381: Public Non-Fungible Token Emote Repository",
                "1",
                block.chainid,
                address(this)
            )
        );

    // Used to avoid double emoting and control undoing
    // emoter address => collection => tokenId => emoji => state (1 for emoted, 0 for not)
    mapping(address => mapping(address => mapping(uint256 => mapping(bytes4 => uint256))))
        private _emotesUsedByEmoter; // Cheaper than using a bool
    // collection => tokenId => emoji => count
    mapping(address => mapping(uint256 => mapping(bytes4 => uint256)))
        private _emotesPerToken;

    /**
     * @inheritdoc IERC6381
     */
    function emoteCountOf(
        address collection,
        uint256 tokenId,
        bytes4 emoji
    ) public view returns (uint256) {
        return _emotesPerToken[collection][tokenId][emoji];
    }

    /**
     * @inheritdoc IERC6381
     */
    function bulkEmoteCountOf(
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis
    ) public view returns (uint256[] memory) {
        if (
            collections.length != tokenIds.length ||
            collections.length != emojis.length
        ) {
            revert BulkParametersOfUnequalLength();
        }

        uint256[] memory counts = new uint256[](collections.length);
        for (uint256 i; i < collections.length; ) {
            counts[i] = _emotesPerToken[collections[i]][tokenIds[i]][emojis[i]];
            unchecked {
                ++i;
            }
        }
        return counts;
    }

    /**
     * @inheritdoc IERC6381
     */
    function hasEmoterUsedEmote(
        address emoter,
        address collection,
        uint256 tokenId,
        bytes4 emoji
    ) public view returns (bool) {
        return _emotesUsedByEmoter[emoter][collection][tokenId][emoji] == 1;
    }

    /**
     * @inheritdoc IERC6381
     */
    function haveEmotersUsedEmotes(
        address[] memory emoters,
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis
    ) public view returns (bool[] memory) {
        if (
            emoters.length != collections.length ||
            emoters.length != tokenIds.length ||
            emoters.length != emojis.length
        ) {
            revert BulkParametersOfUnequalLength();
        }

        bool[] memory states = new bool[](collections.length);
        for (uint256 i; i < collections.length; ) {
            states[i] =
                _emotesUsedByEmoter[emoters[i]][collections[i]][tokenIds[i]][
                    emojis[i]
                ] ==
                1;
            unchecked {
                ++i;
            }
        }
        return states;
    }

    /**
     * @notice Used to emote or undo an emote on a token.
     * @dev Emits ***Emoted*** event.
     * @param collection Address of the collection containing the token being emoted
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     */
    function emote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) public {
        bool currentVal = _emotesUsedByEmoter[msg.sender][collection][tokenId][
            emoji
        ] == 1;
        if (currentVal != state) {
            _beforeEmote(collection, tokenId, emoji, state);
            if (state) {
                _emotesPerToken[collection][tokenId][emoji] += 1;
            } else {
                _emotesPerToken[collection][tokenId][emoji] -= 1;
            }
            _emotesUsedByEmoter[msg.sender][collection][tokenId][emoji] = state
                ? 1
                : 0;
            emit Emoted(msg.sender, collection, tokenId, emoji, state);
            _afterEmote(collection, tokenId, emoji, state);
        }
    }

    /**
     * @notice Used to emote or undo an emote on multiple tokens.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @dev MUST revert if the lengths of the `collections`, `tokenIds`, `emojis` and `states` arrays are not equal.
     * @param collections An array of addresses of the collections containing the tokens being emoted at
     * @param tokenIds An array of IDs of the tokens being emoted
     * @param emojis An array of unicode identifiers of the emojis
     * @param states An array of boolean values signifying whether to emote (`true`) or undo (`false`) emote
     */
    function bulkEmote(
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis,
        bool[] memory states
    ) public {
        if (
            collections.length != tokenIds.length ||
            collections.length != emojis.length ||
            collections.length != states.length
        ) {
            revert BulkParametersOfUnequalLength();
        }

        bool currentVal;
        for (uint256 i; i < collections.length; ) {
            currentVal =
                _emotesUsedByEmoter[msg.sender][collections[i]][tokenIds[i]][
                    emojis[i]
                ] ==
                1;
            if (currentVal != states[i]) {
                _beforeEmote(collections[i], tokenIds[i], emojis[i], states[i]);
                if (states[i]) {
                    _emotesPerToken[collections[i]][tokenIds[i]][
                        emojis[i]
                    ] += 1;
                } else {
                    _emotesPerToken[collections[i]][tokenIds[i]][
                        emojis[i]
                    ] -= 1;
                }
                _emotesUsedByEmoter[msg.sender][collections[i]][tokenIds[i]][
                    emojis[i]
                ] = states[i] ? 1 : 0;
                emit Emoted(
                    msg.sender,
                    collections[i],
                    tokenIds[i],
                    emojis[i],
                    states[i]
                );
                _afterEmote(collections[i], tokenIds[i], emojis[i], states[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC6381
     */
    function prepareMessageToPresignEmote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    collection,
                    tokenId,
                    emoji,
                    state,
                    deadline
                )
            );
    }

    /**
     * @inheritdoc IERC6381
     */
    function bulkPrepareMessagesToPresignEmote(
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis,
        bool[] memory states,
        uint256[] memory deadlines
    ) public view returns (bytes32[] memory) {
        if (
            collections.length != tokenIds.length ||
            collections.length != emojis.length ||
            collections.length != states.length ||
            collections.length != deadlines.length
        ) {
            revert BulkParametersOfUnequalLength();
        }

        bytes32[] memory messages = new bytes32[](collections.length);
        for (uint256 i; i < collections.length; ) {
            messages[i] = keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    collections[i],
                    tokenIds[i],
                    emojis[i],
                    states[i],
                    deadlines[i]
                )
            );
            unchecked {
                ++i;
            }
        }

        return messages;
    }

    /**
     * @notice Used to emote or undo an emote on someone else's behalf.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @dev MUST revert if the lengths of the `collections`, `tokenIds`, `emojis` and `states` arrays are not equal.
     * @dev MUST revert if the `deadline` has passed.
     * @dev MUST revert if the recovered address is the zero address.
     * @param emoter The address that presigned the emote
     * @param collection The address of the collection smart contract containing the token being emoted at
     * @param tokenId IDs of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     * @param deadline UNIX timestamp of the deadline for the signature to be submitted
     * @param v `v` value of an ECDSA signature of the message obtained via `prepareMessageToPresignEmote`
     * @param r `r` value of an ECDSA signature of the message obtained via `prepareMessageToPresignEmote`
     * @param s `s` value of an ECDSA signature of the message obtained via `prepareMessageToPresignEmote`
     */
    function presignedEmote(
        address emoter,
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (block.timestamp > deadline) {
            revert ExpiredPresignedEmote();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        DOMAIN_SEPARATOR,
                        collection,
                        tokenId,
                        emoji,
                        state,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(digest, v, r, s);
        if (signer != emoter) {
            revert InvalidSignature();
        }

        bool currentVal = _emotesUsedByEmoter[signer][collection][tokenId][
            emoji
        ] == 1;
        if (currentVal != state) {
            _beforeEmote(collection, tokenId, emoji, state);
            if (state) {
                _emotesPerToken[collection][tokenId][emoji] += 1;
            } else {
                _emotesPerToken[collection][tokenId][emoji] -= 1;
            }
            _emotesUsedByEmoter[signer][collection][tokenId][emoji] = state
                ? 1
                : 0;
            emit Emoted(signer, collection, tokenId, emoji, state);
            _afterEmote(collection, tokenId, emoji, state);
        }
    }

    /**
     * @notice Used to bulk emote or undo an emote on someone else's behalf.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev MUST emit the `Emoted` event is the state of the emote is changed.
     * @dev MUST revert if the lengths of the `collections`, `tokenIds`, `emojis` and `states` arrays are not equal.
     * @dev MUST revert if the `deadline` has passed.
     * @dev MUST revert if the recovered address is the zero address.
     * @param emoters An array of addresses of the accounts that presigned the emotes
     * @param collections An array of addresses of the collections containing the tokens being emoted at
     * @param tokenIds An array of IDs of the tokens being emoted
     * @param emojis An array of unicode identifiers of the emojis
     * @param states An array of boolean values signifying whether to emote (`true`) or undo (`false`) emote
     * @param deadlines UNIX timestamp of the deadline for the signature to be submitted
     * @param v An array of `v` values of an ECDSA signatures of the messages obtained via `prepareMessageToPresignEmote`
     * @param r An array of `r` values of an ECDSA signatures of the messages obtained via `prepareMessageToPresignEmote`
     * @param s An array of `s` values of an ECDSA signatures of the messages obtained via `prepareMessageToPresignEmote`
     */
    function bulkPresignedEmote(
        address[] memory emoters,
        address[] memory collections,
        uint256[] memory tokenIds,
        bytes4[] memory emojis,
        bool[] memory states,
        uint256[] memory deadlines,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public {
        if (
            emoters.length != collections.length ||
            emoters.length != tokenIds.length ||
            emoters.length != emojis.length ||
            emoters.length != states.length ||
            emoters.length != deadlines.length ||
            emoters.length != v.length ||
            emoters.length != r.length ||
            emoters.length != s.length
        ) {
            revert BulkParametersOfUnequalLength();
        }

        bytes32 digest;
        address signer;
        bool currentVal;
        for (uint256 i; i < collections.length; ) {
            if (block.timestamp > deadlines[i]) {
                revert ExpiredPresignedEmote();
            }
            digest = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(
                            DOMAIN_SEPARATOR,
                            collections[i],
                            tokenIds[i],
                            emojis[i],
                            states[i],
                            deadlines[i]
                        )
                    )
                )
            );
            signer = ecrecover(digest, v[i], r[i], s[i]);
            if (signer != emoters[i]) {
                revert InvalidSignature();
            }

            currentVal =
                _emotesUsedByEmoter[signer][collections[i]][tokenIds[i]][
                    emojis[i]
                ] ==
                1;
            if (currentVal != states[i]) {
                _beforeEmote(collections[i], tokenIds[i], emojis[i], states[i]);
                if (states[i]) {
                    _emotesPerToken[collections[i]][tokenIds[i]][
                        emojis[i]
                    ] += 1;
                } else {
                    _emotesPerToken[collections[i]][tokenIds[i]][
                        emojis[i]
                    ] -= 1;
                }
                _emotesUsedByEmoter[signer][collections[i]][tokenIds[i]][
                    emojis[i]
                ] = states[i] ? 1 : 0;
                emit Emoted(
                    signer,
                    collections[i],
                    tokenIds[i],
                    emojis[i],
                    states[i]
                );
                _afterEmote(collections[i], tokenIds[i], emojis[i], states[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Hook that is called before emote is added or removed.
     * @param collection Address of the collection containing the token being emoted
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     */
    function _beforeEmote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) internal virtual {}

    /**
     * @notice Hook that is called after emote is added or removed.
     * @param collection Address of the collection smart contract containing the token being emoted
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     */
    function _afterEmote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) internal virtual {}

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC6381).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}