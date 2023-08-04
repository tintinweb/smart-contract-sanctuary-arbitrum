/**
 *Submitted for verification at Arbiscan on 2023-08-04
*/

// SPDX-License-Identifier: SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;















/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {




        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {


                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {

        if (returndata.length > 0) {


            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}





contract DeckUpgradeable  {
    struct Card {
        uint8 suit;
        uint8 number;
    }
    event DeckShuffled(uint48 timestamp);

    mapping(uint8 => mapping(uint8 => uint8)) dealtCards;

    uint8[13] cardNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    uint8[4] cardSuits = [1, 2, 3, 4];
    uint256 numberOfDecks;
    uint256 cardsLeft;
    uint256 seedsViewed;
    uint256 seed;
    uint256 lastSeedStamp;

    function _deck_initialize(uint256 _numDecks) internal {
        numberOfDecks = _numDecks;
        cardsLeft = numberOfDecks * 52;
    }
    function randomSeed() internal returns (uint256) {
        if (block.timestamp != lastSeedStamp) {
            seed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((
                                uint256(keccak256(abi.encodePacked(msg.sender)))
                            ) / (block.timestamp)) +
                            block.number +
                            seedsViewed
                    )
                )
            );
            lastSeedStamp = block.timestamp;
        }
        seedsViewed++;
        return (
            ((seed + seedsViewed) - (((seed + seedsViewed) / 1000) * 1000))
        );
    }

    function randomCardNumber() internal returns (uint8) {
        return uint8((randomSeed() % 13) + 1);
    }

    function randomSuit() internal returns (uint8) {
        return uint8((randomSeed() % 4) + 1);
    }

    function notDealt(uint8 _number, uint8 _suit) internal view returns (bool) {
        return dealtCards[_number][_suit] < numberOfDecks;
    }

    function selectRandomCard() internal returns (Card memory card) {
        card.suit = randomSuit();
        card.number = randomCardNumber();
        return card;
    }

    function nextCard() internal returns (Card memory card) {
        card = selectRandomCard();
        while (!notDealt(card.number, card.suit)) {
            card = selectRandomCard();
        }
        dealtCards[card.number][card.suit]++;
        cardsLeft--;
    }

    function shuffleDeck() internal {
        for (uint8 i = 0; i < 13; i++) {
            for (uint8 j = 0; j < 4; j++) {
                dealtCards[cardNumbers[i]][cardSuits[j]] = 0;
            }
        }
        cardsLeft = numberOfDecks * 52;
        emit DeckShuffled(uint48(block.timestamp));
    }
}






interface CasinoInterface {
    function giveChips(address to, uint48 amount) external;
    function takeChips(address to, uint48 amount) external;
    function isMember(address member) external view returns (bool hasMembership);
}

contract GameUpgradeable {
    CasinoInterface public casino;

    address payable owner;

    function _init_game(address _casino, address payable _owner) internal {
        casino = CasinoInterface(_casino);
        owner = _owner;
    }

    modifier onlyMembers() {
        require(
            casino.isMember(msg.sender),
            "Only members can use this function."
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can use this function.");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setCasinoContract(address newContract) public onlyOwner {
        casino = CasinoInterface(newContract);
    }

    function payout(address to, uint48 amount) internal {
        casino.giveChips(to, amount);
    }

    function takeChips(address from, uint48 amount) internal {
        casino.takeChips(from, amount);
    }
    
}

contract BlackJackUpgradeable is  GameUpgradeable, DeckUpgradeable, Initializable, ContextUpgradeable {

  event DealtPlayerCard(
        address player,
        uint8 cardNumber,
        uint8 cardSuit,
        uint8 splitNumber
    );
    event DealtDealerCard(uint8 cardNumber, uint8 cardSuit);
    event DealerRevealedCard(uint8 cardNumber, uint8 cardSuit);
    event DealerBust(uint8 dealerCardsTotal, uint8 dealerCardCount);
    event DealerBlackJack(uint48 timestamp);
    event DealerStand(uint8 dealerCardsTotal, uint8 dealerCardCount);
    event JoinedTable(address player, uint48 timestamp);
    event LeftTable(address player, uint48 timestamp);
    event PlayerWin(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 dealerCardsTotal,
        uint8 splitNumber
    );
    event PlayerBust(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerLost(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerPush(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerHit(
        address player,
        uint8 cardNumber,
        uint8 cardSuit,
        uint8 splitNumber
    );
    event PlayerDoubleDown(
        address player,
        uint48 amount,
        uint8 cardNumber,
        uint8 cardSuit
    );
    event PlayerStand(
        address player,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerBlackJack(address player);
    event PlayerSplit(
        address player,
        uint8 cardNumber,
        uint8 cardSuit1,
        uint8 cardSuit2,
        uint8 splitNumber
    );
    uint48 public bettingPeriod = 1;
    uint48 public lastHandTime;
    address public actingPlayer;
    uint48 public playerActionPeriod = 1;
    uint48 public lastPlayerActionTime;
    uint8 public playersBet;
    mapping(address => Player) public players;
    address[] public playerAddresses;
    Dealer public dealer;
    Card dealerUnrevealed;

    struct PlayerCard {
        Card card;
        uint8 splitNumber;
    }

    struct Player {
        bool atTable;
        uint48 bet;
        PlayerCard[] cards;
        bool doubledDown;
        uint8 highestSplitNumber;
        uint8 splitNumber;
        bool finishedActing;
    }

    struct Dealer {
        Card[] cards;
        bool revealed;
    }
    constructor() {
        _disableInitializers();
    }
    function initialize(address _casino, uint256 _numDecks) external initializer {
        _init_game(_casino, payable(_msgSender()));
        _deck_initialize(_numDecks);
        dealer.revealed = true;
    }
    modifier turnToAct() {
        require(
            msg.sender == actingPlayer ||
                (block.timestamp - lastPlayerActionTime + playerActionPeriod >
                    0),
            "It is not your turn to act"
        );
        _;
    }
    modifier onlyPlayers() {
        require(players[msg.sender].atTable, "You are not at the table");
        _;
    }

    function setTimePeriods(uint48 _bettingPeriod, uint48 _playerActionPeriod)
        external
        onlyOwner
    {
        bettingPeriod = _bettingPeriod;
        playerActionPeriod = _playerActionPeriod;
    }

    function setNumberOfDecks(uint8 _numberOfDecks) external onlyOwner {
        numberOfDecks = _numberOfDecks;
        shuffleDeck();
    }

    function joinTable() external onlyMembers {
        require(
            !players[msg.sender].atTable,
            "You are already sitting at the table."
        );
        require(playerAddresses.length < 255, "The table is full.");
        players[msg.sender].atTable = true;
        playerAddresses.push(msg.sender);
        emit JoinedTable(msg.sender, uint48(block.timestamp));
        seedsViewed++;
    }

    function leaveTable() external onlyPlayers {
        if (players[msg.sender].bet > 0) {
            players[actingPlayer].bet = 0;
            playersBet--;
        }
        players[msg.sender].atTable = false;
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (playerAddresses[i] == msg.sender) {
                address temp = playerAddresses[playerAddresses.length - 1];
                playerAddresses[i] = temp;
                delete playerAddresses[playerAddresses.length - 1];
                emit LeftTable(msg.sender, uint48(block.timestamp));
            }
        }
        if (actingPlayer == msg.sender) {
            actingPlayer = address(0);
            if (playersBet == playerAddresses.length) {
                dealerTurn();
            } else {
                for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
                    if (
                        players[playerAddresses[i]].bet > 0 &&
                        !players[playerAddresses[i]].finishedActing
                    ) {
                        actingPlayer = playerAddresses[i];
                        break;
                    }
                }
                if (actingPlayer == address(0)) dealerTurn();
            }
        }
        seedsViewed++;
    }

    function bet(uint48 amount) external onlyPlayers {
        require(players[msg.sender].bet == 0, "You have already bet");
        require(dealer.revealed, "The round has already started.");
        takeChips(msg.sender, amount);
        players[msg.sender].bet = amount;
        playersBet++;
        if (playersBet == playerAddresses.length) {
            dealCards();
        }
        seedsViewed++;
    }

    function startTheHand() external onlyMembers {
        require(
            block.timestamp - lastHandTime + bettingPeriod > 0,
            "The betting period has not ended"
        );
        require(
            dealer.revealed,
            "The dealer has not revealed their cards yet. Wait until the round ends."
        );
        require(playersBet > 0, "No one has bet yet"); //maybe take this out
        dealCards();
    }

    function moveToNextPlayer() external {
        //require(msg.sender != actingPlayer, "It is your turn to act."); //maybe take this out
        require(!dealer.revealed, "The round has not started.");
        require(
            block.timestamp - lastPlayerActionTime + playerActionPeriod > 0,
            "Wait until the player has had enough time to act."
        );
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (playerAddresses[i] == actingPlayer) {
                emit PlayerLost(
                    actingPlayer,
                    players[actingPlayer].bet,
                    playerCardsTotal(players[actingPlayer].cards, 0),
                    uint8(players[actingPlayer].cards.length),
                    players[actingPlayer].highestSplitNumber
                );
                players[actingPlayer].finishedActing = true;
                if (players[actingPlayer].bet > 0) {
                    players[actingPlayer].bet = 0;
                    playersBet--;
                }
                players[actingPlayer].atTable = false;
                address temp = playerAddresses[playerAddresses.length - 1];
                playerAddresses[i] = temp;
                delete playerAddresses[playerAddresses.length - 1];
                emit LeftTable(actingPlayer, uint48(block.timestamp));
                if (i == playerAddresses.length - 1) {
                    actingPlayer = address(0);
                } else {
                    actingPlayer = playerAddresses[i];
                    lastPlayerActionTime = uint48(block.timestamp);
                }
                break;
            }
        }
        if (actingPlayer == address(0)) {
            dealerTurn();
        }
    }

    function dealCards() internal {
        while (numberOfDecks * 52 - (12 + playerAddresses.length * 12) < 1) numberOfDecks++;
        if (cardsLeft - (12 + playerAddresses.length * 12) < 1) shuffleDeck();
        delete dealer.cards;
        dealer.revealed = false;
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            delete players[playerAddresses[i]].cards;
            players[playerAddresses[i]].doubledDown = false;
            players[playerAddresses[i]].highestSplitNumber = 0;
            players[playerAddresses[i]].splitNumber = 0;
            players[playerAddresses[i]].finishedActing = false;
            if (players[playerAddresses[i]].bet > 0) {
                Card memory next = nextCard();
                players[playerAddresses[i]].cards.push(
                    PlayerCard({card: next, splitNumber: 0})
                );
                emit DealtPlayerCard(
                    playerAddresses[i],
                    next.number,
                    next.suit,
                    players[playerAddresses[i]].splitNumber
                );
            }
        }
        dealer.cards.push(nextCard());
        emit DealtDealerCard(dealer.cards[0].number, dealer.cards[0].suit);
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (players[playerAddresses[i]].bet > 0) {
                Card memory next = nextCard();
                players[playerAddresses[i]].cards.push(
                    PlayerCard({card: next, splitNumber: 0})
                );
                emit DealtPlayerCard(
                    playerAddresses[i],
                    next.number,
                    next.suit,
                    players[playerAddresses[i]].splitNumber
                );
            }
        }
        dealerUnrevealed = nextCard();
        bool dealerBlackjack = (dealer.cards[0].number == 1 &&
            dealerUnrevealed.number >= 10) ||
            (dealer.cards[0].number >= 10 && dealerUnrevealed.number == 1);
        if (dealerBlackjack) {
            dealer.cards.push(dealerUnrevealed); //could be removed..
            dealer.revealed = true;
            emit DealerRevealedCard(
                dealerUnrevealed.number,
                dealerUnrevealed.suit
            );
            emit DealerBlackJack(uint48(block.timestamp));
            lastHandTime = uint48(block.timestamp);
            playersBet = 0;
        }
        for (uint8 i; i < uint8(playerAddresses.length); i++) {
            if (players[playerAddresses[i]].bet > 0) {
                uint8 cardTotal = playerCardsTotal(
                    players[playerAddresses[i]].cards,
                    0
                );
                if (dealerBlackjack) {
                    if (cardTotal == 21) {
                        emit PlayerPush(
                            playerAddresses[i],
                            players[playerAddresses[i]].bet,
                            cardTotal,
                            uint8(players[playerAddresses[i]].cards.length),
                            players[playerAddresses[i]].splitNumber
                        );
                        payout(
                            playerAddresses[i],
                            players[playerAddresses[i]].bet
                        );
                    } else {
                        emit PlayerLost(
                            playerAddresses[i],
                            players[playerAddresses[i]].bet,
                            cardTotal,
                            uint8(players[playerAddresses[i]].cards.length),
                            players[playerAddresses[i]].splitNumber
                        );
                    }
                    players[playerAddresses[i]].finishedActing = true;
                    players[playerAddresses[i]].bet = 0;
                } else {
                    if (cardTotal == 21) {
                        emit PlayerBlackJack(playerAddresses[i]);
                        uint48 winnings = players[playerAddresses[i]].bet + ((players[playerAddresses[i]].bet *
                            3) / 2);
                        payout(playerAddresses[i], winnings);
                        emit PlayerWin(
                            playerAddresses[i],
                            winnings,
                            cardTotal,
                            uint8(players[playerAddresses[i]].cards.length),
                            players[playerAddresses[i]].splitNumber
                        );
                        players[playerAddresses[i]].bet = 0;
                        players[playerAddresses[i]].finishedActing = true;
                    } else if (actingPlayer == address(0)) {
                        actingPlayer = playerAddresses[i];
                        lastPlayerActionTime = uint48(block.timestamp);
                    }
                }
            }
        }
        if (actingPlayer == address(0) && !dealer.revealed) {
            dealer.revealed = true;
            emit DealerRevealedCard(dealerUnrevealed.number, dealerUnrevealed.suit);
            dealer.cards.push(dealerUnrevealed);
            playersBet = 0;
        }
    }

    function cardsTotal(Card[] memory cards)
        internal
        pure
        returns (uint8 cardTotal)
    {
        uint8 aceCount;
        for (uint8 i = 0; i < uint8(cards.length); i++) {
            if (cards[i].number == 1) {
                aceCount++;
            } else {
                cardTotal += cards[i].number < 10 ? cards[i].number : 10;
            }
        }
        while (aceCount > 0) {
                if (cardTotal + 11 <= 21) {
                    cardTotal += 11;
                } else {
                    cardTotal++;
                }
            aceCount--;
        }
    }

    function playerCardsTotal(PlayerCard[] memory cards, uint8 splitToPlay)
        internal
        pure
        returns (uint8 cardTotal)
    {
        uint8 aceCount;
        for (uint8 i = 0; i < uint8(cards.length); i++) {
            if (cards[i].splitNumber == splitToPlay) {
                if (cards[i].card.number == 1) {
                    aceCount++;
                } else {
                    cardTotal += cards[i].card.number < 10
                        ? cards[i].card.number
                        : 10;
                }
            }
        }
        while (aceCount > 0) {
                if (cardTotal + 11 <= 21) {
                    cardTotal += 11;
                } else {
                    cardTotal++;
                }
            aceCount--;
        }
    }

    function cardsOfSplit(PlayerCard[] memory cards, uint8 splitToPlay)
        internal
        pure
        returns (uint8 count)
    {
        for (uint256 i = 0; i < cards.length; i++) {
            if (cards[i].splitNumber == splitToPlay) {
                count++;
            }
        }
    }

    function dealerTurn() internal {
        dealer.revealed = true;
        emit DealerRevealedCard(dealerUnrevealed.number, dealerUnrevealed.suit);
        dealer.cards.push(dealerUnrevealed);
        bool shouldDealerPlay = false;
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (players[playerAddresses[i]].bet > 0) {
                shouldDealerPlay = true;
                break;
            }
        }
        if (shouldDealerPlay) {
            uint8 dealerCardTotal = cardsTotal(dealer.cards);
            while (dealerCardTotal < 17) {
                Card memory next = nextCard();
                dealer.cards.push(next);
                emit DealtDealerCard(next.number, next.suit);
                dealerCardTotal = cardsTotal(dealer.cards);
            }
            if (dealerCardTotal > 21) {
                emit DealerBust(dealerCardTotal, uint8(dealer.cards.length));
            } else {
                emit DealerStand(dealerCardTotal, uint8(dealer.cards.length));
            }
/*             address firstPlayer = address(
                playerAddresses[playerAddresses.length - 1]
            ); */
            for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
                if (players[playerAddresses[i]].bet > 0) {
                    for (
                        uint8 z = 0;
                        z <= players[playerAddresses[i]].splitNumber;
                        z++
                    ) {
                        uint8 cardTotal = playerCardsTotal(
                            players[playerAddresses[i]].cards,
                            z
                        );
                        uint8 splitCardCount = cardsOfSplit(
                            players[playerAddresses[i]].cards,
                            z
                        );
                        if (dealerCardTotal > 21) {
                            uint48 winnings = players[playerAddresses[i]].highestSplitNumber > 0
                                ? (players[playerAddresses[i]].bet /
                                    (players[playerAddresses[i]].highestSplitNumber+1)) * 2
                                : players[playerAddresses[i]].bet * 2;
                            payout(playerAddresses[i], winnings);
                            emit PlayerWin(
                                playerAddresses[i],
                                winnings,
                                cardTotal,
                                splitCardCount,
                                z
                            );
                        } else {
                            if (cardTotal > dealerCardTotal) {
                                uint48 winnings = players[playerAddresses[i]].highestSplitNumber > 0
                                    ? (players[playerAddresses[i]].bet /
                                        (players[playerAddresses[i]].highestSplitNumber+1)) * 2
                                    : players[playerAddresses[i]].bet * 2;
                                payout(playerAddresses[i], winnings);
                                emit PlayerWin(
                                    playerAddresses[i],
                                    winnings,
                                    cardTotal,
                                    splitCardCount,
                                    z
                                );
                            } else if (cardTotal == dealerCardTotal) {
                                payout(
                                    playerAddresses[i],
                                    players[playerAddresses[i]].highestSplitNumber > 0
                                        ? (players[playerAddresses[i]].bet /
                                            (players[playerAddresses[i]].highestSplitNumber+1))
                                        : players[playerAddresses[i]].bet
                                );
                                emit PlayerPush(
                                    playerAddresses[i],
                                    players[playerAddresses[i]].bet,
                                    cardTotal,
                                    splitCardCount,
                                    z
                                );
                            } else {
                                emit PlayerLost(
                                    playerAddresses[i],
                                    players[playerAddresses[i]].bet,
                                    cardTotal,
                                    splitCardCount,
                                    z
                                );
                            }
                        }
                    }
                    players[playerAddresses[i]].bet = 0;
                /*     if (i == playerAddresses.length - 1) {
                        playerAddresses[i] = firstPlayer;
                    } else {
                        playerAddresses[i] = playerAddresses[i + 1];
                    } */
                }
            }
        }
        lastHandTime = uint48(block.timestamp);
        playersBet = 0;
    }

    function hit() external turnToAct {
        Card memory next = nextCard();
        players[msg.sender].cards.push(
            PlayerCard({
                card: next,
                splitNumber: players[msg.sender].splitNumber
            })
        );
        emit DealtPlayerCard(
            msg.sender,
            next.number,
            next.suit,
            players[msg.sender].splitNumber
        );
        emit PlayerHit(
            msg.sender,
            next.number,
            next.suit,
            players[msg.sender].splitNumber
        );
        uint8 cardTotal = playerCardsTotal(
            players[msg.sender].cards,
            players[msg.sender].splitNumber
        );
        if (cardTotal == 21) {
            if (
                players[msg.sender].splitNumber ==
                players[msg.sender].highestSplitNumber
            ) {
                players[msg.sender].finishedActing = true;
            } else {
                players[msg.sender].splitNumber++;
            }
            actingPlayer = address(0);
        } else if (cardTotal > 21) {
            emit PlayerBust(
                msg.sender,
                players[msg.sender].bet,
                cardTotal,
                uint8(players[msg.sender].cards.length),
                players[msg.sender].splitNumber
            );
            players[msg.sender].finishedActing = true;
            players[msg.sender].bet = 0;
            actingPlayer = address(0);
        }
        if (players[msg.sender].finishedActing) {
            for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
                if (
                    players[playerAddresses[i]].bet > 0 &&
                    !players[playerAddresses[i]].finishedActing
                ) {
                    actingPlayer = playerAddresses[i];
                    lastPlayerActionTime = uint48(block.timestamp);
                    break;
                }
            }
        } else {
            lastPlayerActionTime = uint48(block.timestamp);
        }
        if (actingPlayer == address(0)) {
            dealerTurn();
        }
        seedsViewed++;
    }

    function stand() public turnToAct {
        uint8 cardCount = cardsOfSplit(players[msg.sender].cards, players[msg.sender].splitNumber);
        uint8 cardTotal = playerCardsTotal(players[msg.sender].cards, players[msg.sender].splitNumber);
        emit PlayerStand(msg.sender, cardTotal, cardCount, players[msg.sender].splitNumber);
        if (
            players[msg.sender].splitNumber <
            players[msg.sender].highestSplitNumber
        ) {
            players[msg.sender].splitNumber++;
        } else {
            players[msg.sender].finishedActing = true;
            actingPlayer = address(0);
            for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
                if (
                    players[playerAddresses[i]].bet > 0 &&
                    !players[playerAddresses[i]].finishedActing
                ) {
                    actingPlayer = playerAddresses[i];
                    lastPlayerActionTime = uint48(block.timestamp);
                    break;
                }
            }
            if (actingPlayer == address(0)) {
                dealerTurn();
            }
        }
        seedsViewed++;
    }

    function doubleDown() external turnToAct {
        require(
            players[msg.sender].cards.length == 2,
            "You can only double down on your first two cards"
        );
        takeChips(msg.sender, players[msg.sender].bet);
        players[msg.sender].bet *= 2;
        players[msg.sender].doubledDown = true;
        Card memory next;
        next = nextCard();
        players[msg.sender].cards.push(
            PlayerCard({
                card: next,
                splitNumber: players[msg.sender].splitNumber
            })
        );
        emit PlayerDoubleDown(
            msg.sender,
            players[msg.sender].bet,
            next.number,
            next.suit
        );
        emit DealtPlayerCard(
            msg.sender,
            next.number,
            next.suit,
            players[msg.sender].splitNumber
        );
        players[msg.sender].finishedActing = true;
        actingPlayer = address(0);
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (
                players[playerAddresses[i]].bet > 0 &&
                !players[playerAddresses[i]].finishedActing
            ) {
                actingPlayer = playerAddresses[i];
                lastPlayerActionTime = uint48(block.timestamp);
                break;
            }
        }
        if (actingPlayer == address(0)) {
            dealerTurn();
        }
        seedsViewed++;
    }

    function split() external turnToAct {
        uint8 cardNumber;
        uint8 cardSuit;
        takeChips(
            msg.sender,
            players[msg.sender].bet / players[msg.sender].highestSplitNumber
        );
        if (players[msg.sender].cards.length == 2) {
            for (uint8 i; i < uint8(players[msg.sender].cards.length); i++) {
                if (
                    (players[msg.sender].cards[i].splitNumber ==
                        players[msg.sender].splitNumber) &&
                    (cardNumber < 1 ||
                        (cardNumber ==
                            players[msg.sender].cards[i].card.number))
                ) {
                    if (cardNumber < 1) {
                        cardNumber = players[msg.sender].cards[i].card.number;
                        cardSuit = players[msg.sender].cards[i].card.suit;
                    } else {
                        emit PlayerSplit(
                            msg.sender,
                            cardNumber,
                            cardSuit,
                            players[msg.sender].cards[i].card.suit,
                            players[msg.sender].splitNumber
                        );
                        Card memory next;
                        next = nextCard();
                        players[msg.sender].cards.push(
                            PlayerCard({
                                card: next,
                                splitNumber: players[msg.sender].splitNumber
                            })
                        );
                        emit DealtPlayerCard(
                            msg.sender,
                            next.number,
                            next.suit,
                            players[msg.sender].splitNumber
                        );
                        next = nextCard();
                        players[msg.sender].cards.push(
                            PlayerCard({
                                card: next,
                                splitNumber: players[msg.sender]
                                    .highestSplitNumber + 1
                            })
                        );
                        players[msg.sender].highestSplitNumber++;
                        emit DealtPlayerCard(
                            msg.sender,
                            next.number,
                            next.suit,
                            players[msg.sender].highestSplitNumber + 1
                        );
                        break;
                    }
                } else if (
                    players[msg.sender].cards[i].splitNumber ==
                    players[msg.sender].splitNumber
                ) {
                    cardNumber = 0;
                }
            }
        }
        require(cardNumber > 0, "Invalid split");
        lastPlayerActionTime = uint48(block.timestamp);
        seedsViewed++;
    }
}