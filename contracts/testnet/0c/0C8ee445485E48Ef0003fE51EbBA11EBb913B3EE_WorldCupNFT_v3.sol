//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./WorldCupHelpers.sol";

/*
    World Cup Quatar 2022

    ---- Teams ----
    00. Unset

    Group A: 01. Qatar           02. Ecuador         03. Senegal         04. Netherlands
    Group B: 05. England         06. Iran            07. USA             08. Wales
    Group C: 09. Argentina       10. Saudi Arabia    11. Mexico          12. Poland
    Group D: 13. France          14. Australia       15. Denmark         16. Tunisia
    Group E: 17. Spain           18. Costa Rica      19. Germany         20. Japan
    Group F: 21. Belgium         22. Canada          23. Morocco         24. Croatia
    Group G: 25. Brazil          26. Serbia          27. Switzerland     28. Cameroon
    Group H: 29. Portugal        30. Ghana           31. Uruguay         32. South Korea

    F_A --|                                                               |-- F_B
          |-- W_8A --|                                         |-- W_8B --|
    S_B --|          |                                         |          |-- S_A
                     |-- W_4A --|                   |-- W_4B --|
    F_C --|          |          |                   |          |          |-- F_D
          |-- W_8C --|          |                   |          |-- W_8D --|
    S_D --|                     |                   |                     |-- S_C
                                |-- W_2A vs. W_2B --|
    F_E --|                     |                   |                     |-- F_F
          |-- W_8E --|          |                   |          |-- W_8F --|
    S_F --|          |          |                   |          |          |-- S_E
                     |-- W_4C --|                   |-- W_4D --|
    F_G --|          |                                         |          |-- F_H
          |-- W_8G --|                                         |-- W_8H --|
    S_H --|                                                               |-- S_G

    ---- Group Stage ----
    Group A - First match: Mon, Nov. 21, 5 AM ET (1669017600) >> F_A & S_A
    Group B - First match: Mon, Nov. 21, 8 AM ET (1669028400) >> F_B & S_B
    Group C - First match: Tue, Nov. 22, 5 AM ET (1669104000) >> F_C & S_C
    Group D - First match: Tue, Nov. 22, 8 AM ET (1669114800) >> F_D & S_D
    Group E - First match: Wed, Nov. 23, 5 AM ET (1669190400) >> F_E & S_E
    Group F - First match: Wed, Nov. 23, 8 AM ET (1669201200) >> F_F & S_F
    Group G - First match: Thu, Nov. 24, 5 AM ET (1669276800) >> F_G & S_G
    Group H - First match: Thu, Nov. 24, 8 AM ET (1669287600) >> F_H & S_H

    ---- Round of 16 ----
    Match 8A: F_A vs S_B (Valid teams: 01-04 vs 05-08) >> Sat, Dec. 3, 10 AM ET (1670072400) >> W_8A
    Match 8B: F_B vs S_A (Valid teams: 01-04 vs 05-08) >> Sun, Dec. 4, 2 PM ET  (1670173200) >> W_8B
    Match 8C: F_C vs S_D (Valid teams: 09-12 vs 13-16) >> Sat, Dec. 3, 2 PM ET  (1670086800) >> W_8C
    Match 8D: F_D vs S_C (Valid teams: 09-12 vs 13-16) >> Sun, Dec. 4, 10 AM ET (1670158800) >> W_8D
    Match 8E: F_E vs S_F (Valid teams: 17-20 vs 21-24) >> Mon, Dec. 5, 10 AM ET (1670245200) >> W_8E
    Match 8F: F_F vs S_E (Valid teams: 17-20 vs 21-24) >> Tue, Dec. 6, 10 AM ET (1670331600) >> W_8F
    Match 8G: F_G vs S_H (Valid teams: 25-28 vs 29-32) >> Mon, Dec. 5, 2 PM ET  (1670259600) >> W_8G
    Match 8H: F_H vs S_G (Valid teams: 25-28 vs 29-32) >> Tue, Dec. 6, 2 PM ET  (1670346000) >> W_8H

    ---- Quarter Finals ----
    Match 4A: W_8A vs W_8C (Valid teams: F_A, S_B, F_C, S_D)  >> Fri, Dec. 9, 2 PM ET   (1670605200) >> W_4A
    Match 4B: W_8B vs W_8D (Valid teams: F_B, S_A, F_D, S_C)  >> Sat, Dec. 10, 2 PM ET  (1670691600) >> W_4B
    Match 4C: W_8E vs W_8G (Valid teams: F_E, S_F, F_G, S_H)  >> Fri, Dec. 9, 10 AM ET  (1670590800) >> W_4C
    Match 4D: W_8F vs W_8H (Valid teams: F_F, S_E, F_H, S_G)  >> Sat, Dec. 10, 10 AM ET (1670677200) >> W_4D

    ---- Semi-Finals ----
    Match 2A: W_4A vs W_4C (Valid teams: W_8A, W_8C, W_8E, W_8G)  >> Tue, Dec. 13, 2 PM ET (1670950800) >> W_2A
    Match 2B: W_4B vs W_4D (Valid teams: W_8B, W_8D, W_8F, W_8H)  >> Wed, Dec. 14, 2 PM ET (1671037200) >> W_2B

    ---- 3rd Place ----
    Match TRP: L_2A vs L_2B (Valid teams: W_4A, W_4C, W_4B, W_4D)  >> Sat, Dec. 17, 10 AM ET (1671282000) >> THRD

    ---- Final ----
    Match FNL: W_2A vs W_2B (Valid teams: W_4A, W_4C, W_4B, W_4D)  >> Sun, Dec. 18, 10 AM ET (1671368400) >> FRST + SCND

    ---- Winners ----
    FRST  (Valid teams: W_2A, W_2B)
    SCND  (Valid teams: W_2A, W_2B)
    THRD  (Valid teams: L_2A, L_2B)
    [Third place is only available to those who completely fill up their fixtures and provides a power boost]

    ---- How it works ----
    1) Users mint their NFT Predictions via mint(). They load their predictions with some value (>= 0.01 ETH).
    2) A whitelisted Oracle address updates the results via updateResults().
    3) Users can continue minting Predictions as results are settled, but settled results will be discounted as wrong.
       After W_8A_DEADLINE, no more Predictions can be minted.
    4) Once all results are set, the Oracle calls finalizeOracle().
    5) During the next 3 days, users can register their winning Predictions for a claim on the treasury.
    6) Predictions have points (based on the amount of correct and incorrect predictions) which is multiplied
       with their set value (in ETH) to calculate their treasury shares.
    7) Once all winning Predictions are registered, the treasury (minus a 5% protocol fee) is divided by the
       total sum of treasury shares.
    8) Users can then claim their part of the treasury (points * value)/totalShares.
    9) 30 days after prize redemption starts, Owner is allowed to withdraw any remaining balance.

*/

contract WorldCupNFT_v3 is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 constant private FEE = 5;                           //Fixed protocol fee: 5%.

    uint256 public deadlineGap = 1 hours;                       //When checking a deadline, this value is substracted. Can be set by Owner.

    uint256 public registerWinnersDeadline;                     //Set when oracle is finalized to 3 daays after the fact. 
    uint256 public totalTreasuryForPrizes;                      //Treasury left after 5% fee (calculated once oracle is finalized).
    uint256 public totalProtocolFees;                           //Fees to be withdrawn by the protocol (calculated once oracle is finalized).
    uint256 public totalShares;                                 //Sum of every winning, registered Prediction's score during the winners registration period.

    mapping(uint256 => WorldCupHelpers.Fixture) private predictions;    //The predictions of each NFT.
    WorldCupHelpers.Fixture private results;                            //The current results as a Fixture. Controlled by the Oracle.
 
    mapping(uint256 => bool) public registeredPredictions;      //Mapping of which winning Predictions have been registered.
    mapping(uint256 => bool) public claimedPredictions;         //Mapping of which winning Predictions have claimed their share of treasury.

    address public oracleAddress;                               //Address of the oracle which can update the results. It's set by the Owner, and can be fixed via fixedOracleAddress.
    address public feeWithdrawalAddress;                        //Address where fees are withdrawn after oracle is finalized. Can also be fixed via fixedFeeWithdrawAddress.
                                                                //This address can also withdraw any remaining/unclaimed funds 30 days after the prize redemption starts.
    bool public enabled;
    bool public fixedOracleAddress;             
    bool public fixedFeeWithdrawalAddress;

    string private baseUri;

    error OracleFixed();
    error DevWithdrawFixed();
    error NotEnabled();
    error WrongValue();
    error InvalidFixture();
    error IdNotFound(uint256);
    error NotOracle();
    error OracleFinished();
    error NotFinished();
    error TransferError();
    error WinnerRegistrationFinished();
    error WinnerAlreadySet();
    error NotWinner();
    error NotOwner();
    error NotRegistered();
    error WinnerRegistrationNotFinished();
    error AlreadyClaimed();
    error EmergencyModeAlreadyActive();
    error NotEmergency();
    
    event MintPrediction(address owner, uint256 id, WorldCupHelpers.Fixture prediction);
    event StateUpdate(uint8 n, uint8 value);
    event RegisteredWinner(uint256 id, uint256 shares);

    //INITIALIZE AND SET OPERATION VARIABLES

    constructor(address oracle, address feeWithdraw, string memory uri) ERC721("WC2022", "WorldCup2022 Prediction") {
        oracleAddress = oracle;
        feeWithdrawalAddress = feeWithdraw;
        baseUri = uri;
    }

    function setOracleAddress(address oracle, bool fix) public onlyOwner {
        if (fixedOracleAddress) { revert OracleFixed(); }
        oracleAddress = oracle;
        fixedOracleAddress = fix;
    }

    function setFeeWithdrawalAddress(address devWithdraw, bool fix) public onlyOwner {
        if (fixedFeeWithdrawalAddress) { revert DevWithdrawFixed(); }
        feeWithdrawalAddress = devWithdraw;
        fixedFeeWithdrawalAddress = fix;
    }

    function setDeadlineGap(uint256 gap) public onlyOwner {
        deadlineGap = gap;
    }

    function start() public onlyOwner {
        enabled = true;
    }


    //MINTING AND GETTING PREDICTIONS 

    function mint(WorldCupHelpers.Fixture memory prediction) external payable {
        if (!enabled) { revert NotEnabled(); }

        //Check the value in the prediction is OK and it's greater than 0.01 ETH
        if (msg.value != prediction.value) { revert WrongValue(); }       
        if (msg.value < 0.01 ether) { revert WrongValue(); }

        //Fixture must be valid (no contradictory results, missing predictions or mint after the W_2A deadline)
        prediction.timestamp = block.timestamp;
        if (!WorldCupHelpers.isPredictionValid(prediction, true, deadlineGap)) { revert InvalidFixture(); }

        //Fixture must be current (all predictions match settled results)
        if (WorldCupHelpers.isPredictionCurrent(prediction, results)) { revert InvalidFixture(); }

        uint256 newId = totalSupply() + 1;
        predictions[newId] = prediction;
        _safeMint(_msgSender(), newId);

        //results.value sums every individual Predictions's value.
        //It should equal address(this).balance before withdrawals.
        results.value += prediction.value;
        
        emit MintPrediction(_msgSender(), newId, prediction);
    }

    //Get a given fixture (with ID)
    function getPrediction(uint256 id) external view returns (WorldCupHelpers.Fixture memory) {
        if (!_exists(id)) { revert IdNotFound(id); }
        return predictions[id];
    }


    //UPDATING AND GETTING STATE

    //Function used by the Oracle to update results, which can be overwritten in case of error
    //FOR TESTING PURPOSES a 0 UPDATE IS ALLOWED AND TIMESTAMP IS NOT VERIFIED!
    function updateResults(uint8 n, uint8 value) external onlyOracle {
        if (registerWinnersDeadline > 0) { revert OracleFinished(); }
        results = WorldCupHelpers.stateTransition(results, n, value, block.timestamp);
        emit StateUpdate(n, value);
    }

    function getCurrentResults() external view returns (WorldCupHelpers.Fixture memory) {return results; }

    //Once all 32 results have been set, the Oracle calls this function to make them immutable.
    //The function sets registerWinnersDeadline to 3 days after the call, establishing a period to manually register all winning Predictions
    //Calling this function is the last duty of the oracle.
    function finalizeOracle() external onlyOracle {
        if (registerWinnersDeadline > 0) { revert OracleFinished(); }
        
        //To finalize the Oracle, the state must be valid
        if (!WorldCupHelpers.isPredictionValid(results, false, deadlineGap)) { revert InvalidFixture(); }

        registerWinnersDeadline = block.timestamp + (3 days);

        //This function also calculates totalProtocolFees, and totalTreasuryForPrizes
        uint256 totalTreasury = address(this).balance;
        totalProtocolFees = (totalTreasury * FEE)/100;
        totalTreasuryForPrizes = totalTreasury - totalProtocolFees;

        emit StateUpdate(32, 0);
    }


    //PROTOCOL WITHDRAWAL

    function withdraw() external onlyOwner {
        if (registerWinnersDeadline == 0) { revert NotFinished(); }
        if (block.timestamp < (registerWinnersDeadline + 30 days)) {
            //5% Fee withdrawal
            (bool transfer,) = payable(feeWithdrawalAddress).call{value: totalProtocolFees}("");
            if (!transfer) { revert TransferError(); }
        } else {
            //30 days after prize redemption starts, any remaining balance can be recovered
            (bool transfer,) = payable(feeWithdrawalAddress).call{value: address(this).balance}("");
            if (!transfer) { revert TransferError(); }
        }
    }


    //REGISTER WINNERS AFTER ORACLE IS FINISHED

    //Calculate a fixture points
    function getPredictionPoints(uint256 id) public view returns (uint256) {
        if (!_exists(id)) { revert IdNotFound(id); }
        uint256 points = WorldCupHelpers.calcPredictionPoints(predictions[id], results, deadlineGap);
        if (points == 0) { revert NotWinner(); }
        return points;
    }

    //After finalizeOracle() is called, and before registerWinnersDeadline is reached (3 days after that), this function must register every winning Prediction.
    //Registration is required to be able to claim a portion of the treasury. Failure to register will result in a complete loss of any claim on the treasury.
    //Registration is open to the public, and only requires the ID of a winning Fixture (a fixture with calcPredictionPoints() > 0).
    function registerWinner(uint id) external {
        if (registerWinnersDeadline == 0) { revert NotFinished(); }
        if (block.timestamp > registerWinnersDeadline) { revert WinnerRegistrationFinished(); }
        if (registeredPredictions[id]) { revert WinnerAlreadySet(); }

        uint256 shares = getPredictionPoints(id) * predictions[id].value;
        totalShares += shares;
        registeredPredictions[id] = true;

        emit RegisteredWinner(id, shares);
    }


    //CLAIM FROM TREASURY

    //After registerWinnersDeadline is reached, owners of winning, registered Predictions can begin to claim their treasury share.   
    //There's a time limit of 30 days after registerWinnersDeadline to claim from treasury.
    //After that, owner could decide to withdraw remaining balance to feeWithdrawalAddress.
    function claimFromTreasury(uint id) external {
        if (ownerOf(id) != _msgSender()) { revert NotOwner(); }
  
        if (registeredPredictions[id]) { revert NotRegistered(); }
        if (claimedPredictions[id]) { revert AlreadyClaimed(); }
        if (block.timestamp < registerWinnersDeadline) { revert WinnerRegistrationNotFinished(); }

        uint256 shares = getPredictionPoints(id) * predictions[id].value;

        claimedPredictions[id] = true;
    
        uint256 prize = (totalTreasuryForPrizes * shares)/totalShares;
        (bool transfer,) = payable(_msgSender()).call{value: prize}("");
        if (!transfer) { revert TransferError(); }
    }


    //OTHER

    //Set and Get tokenURI
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) { revert IdNotFound(id); }
        return string(abi.encodePacked(baseUri, id.toString()));
    }
    function setBaseURI(string memory newUri) external onlyOwner {
        baseUri = newUri;
    }

    //Modifier for Oracle access.
    modifier onlyOracle() {
        if (oracleAddress != _msgSender()) { revert NotOracle(); }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library WorldCupHelpers {

    uint256 constant private GROUP_A_DEADLINE = 1657071000;                       //1669017600;     //Date of first Group A match.
    uint256 constant private GROUP_B_DEADLINE = GROUP_A_DEADLINE + 2 minutes;     //1669028400;     //Date of first Group B match.
    uint256 constant private GROUP_C_DEADLINE = GROUP_A_DEADLINE + 4 minutes;     //1669104000;     //Date of first Group C match.
    uint256 constant private GROUP_D_DEADLINE = GROUP_A_DEADLINE + 6 minutes;     //1669114800;     //Date of first Group D match.
    uint256 constant private GROUP_E_DEADLINE = GROUP_A_DEADLINE + 8 minutes;     //1669190400;     //Date of first Group E match.
    uint256 constant private GROUP_F_DEADLINE = GROUP_A_DEADLINE + 10 minutes;    //1669201200;     //Date of first Group F match.
    uint256 constant private GROUP_G_DEADLINE = GROUP_A_DEADLINE + 12 minutes;    //1669276800;     //Date of first Group G match.
    uint256 constant private GROUP_H_DEADLINE = GROUP_A_DEADLINE + 14 minutes;    //1669287600;     //Date of first Group H match.

    uint256 constant private W_8A_DEADLINE = GROUP_A_DEADLINE + 16 minutes;       //1670072400;     //Date of match 8A.
    uint256 constant private W_8B_DEADLINE = GROUP_A_DEADLINE + 22 minutes;       //1670173200;     //Date of match 8B.
    uint256 constant private W_8C_DEADLINE = GROUP_A_DEADLINE + 18 minutes;       //1670086800;     //Date of match 8C.
    uint256 constant private W_8D_DEADLINE = GROUP_A_DEADLINE + 20 minutes;       //1670158800;     //Date of match 8D.
    uint256 constant private W_8E_DEADLINE = GROUP_A_DEADLINE + 24 minutes;       //1670245200;     //Date of match 8E.
    uint256 constant private W_8F_DEADLINE = GROUP_A_DEADLINE + 28 minutes;       //1670331600;     //Date of match 8F.
    uint256 constant private W_8G_DEADLINE = GROUP_A_DEADLINE + 26 minutes;       //1670259600;     //Date of match 8G.
    uint256 constant private W_8H_DEADLINE = GROUP_A_DEADLINE + 30 minutes;       //1670346000;     //Date of match 8H.

    uint256 constant private W_4A_DEADLINE = GROUP_A_DEADLINE + 34 minutes;       //1670605200;     //Date of match 4A.
    uint256 constant private W_4B_DEADLINE = GROUP_A_DEADLINE + 36 minutes;       //1670691600;     //Date of match 4B.
    uint256 constant private W_4C_DEADLINE = GROUP_A_DEADLINE + 32 minutes;       //1670590800;     //Date of match 4C.
    uint256 constant private W_4D_DEADLINE = GROUP_A_DEADLINE + 38 minutes;       //1670677200;     //Date of match 4D.

    uint256 constant private W_2A_DEADLINE = GROUP_A_DEADLINE + 40 minutes;       //1670950800;     //Date of match 2A.
    uint256 constant private W_2B_DEADLINE = GROUP_A_DEADLINE + 42 minutes;       //1671037200;     //Date of match 2B.

    uint256 constant private THIRD_DEADLINE = GROUP_A_DEADLINE + 44 minutes;      //1671282000;     //Date of 3rd. Place match.
    uint256 constant private FINAL_DEADLINE = GROUP_A_DEADLINE + 46 minutes;      //1671368400;     //Date of final match.

    struct Fixture {
        uint8 F_A; uint8 F_B; uint8 F_C; uint8 F_D; uint8 F_E; uint8 F_F; uint8 F_G; uint8 F_H;
        uint8 S_A; uint8 S_B; uint8 S_C; uint8 S_D; uint8 S_E; uint8 S_F; uint8 S_G; uint8 S_H;

        uint8 W_8A; uint8 W_8B; uint8 W_8C; uint8 W_8D; uint8 W_8E; uint8 W_8F; uint8 W_8G; uint8 W_8H;
        uint8 W_4A; uint8 W_4B; uint8 W_4C; uint8 W_4D;
        uint8 W_2A; uint8 W_2B;
        
        uint8 FRST; uint8 THRD;
        
        uint256 timestamp;
        uint256 value;
    }

    error Invalid();

    //Finds out if a Prediction is valid
    //Returns true if there are no contradictory results or missing predictions
    function isPredictionValid(Fixture memory prediction, bool verifyTimestamp, uint256 gap) external pure returns (bool) {
        //For every group A-H:
        // - Checks if the F_A (1st. Group A Team) and S_A (2nd. Group A Team) predictions belong to Group A and are different between each other
        if (!(prediction.F_A >=1  && prediction.F_A <=4  && prediction.S_A >=1  && prediction.S_A <=4  && prediction.F_A != prediction.S_A)) { return false; }
        if (!(prediction.F_B >=5  && prediction.F_B <=8  && prediction.S_B >=5  && prediction.S_B <=8  && prediction.F_B != prediction.S_B)) { return false; }
        if (!(prediction.F_C >=9  && prediction.F_C <=12 && prediction.S_C >=9  && prediction.S_C <=12 && prediction.F_C != prediction.S_C)) { return false; }
        if (!(prediction.F_D >=12 && prediction.F_D <=16 && prediction.S_D >=12 && prediction.S_D <=16 && prediction.F_D != prediction.S_D)) { return false; }
        if (!(prediction.F_E >=17 && prediction.F_E <=20 && prediction.S_E >=17 && prediction.S_E <=20 && prediction.F_E != prediction.S_E)) { return false; }
        if (!(prediction.F_F >=21 && prediction.F_F <=24 && prediction.S_F >=21 && prediction.S_F <=24 && prediction.F_F != prediction.S_F)) { return false; }
        if (!(prediction.F_G >=25 && prediction.F_G <=28 && prediction.S_G >=25 && prediction.S_G <=28 && prediction.F_G != prediction.S_G)) { return false; }
        if (!(prediction.F_H >=29 && prediction.F_H <=32 && prediction.S_H >=29 && prediction.S_H <=32 && prediction.F_H != prediction.S_H)) { return false; }

        //For every match after group phase and the first place:
        // - Checks that each winner is equal to one of the two participants of the prvious, corresponding match.
        if (prediction.W_8A != prediction.F_A && prediction.W_8A != prediction.S_B) { return false; }
        if (prediction.W_8B != prediction.F_B && prediction.W_8B != prediction.S_A) { return false; }
        if (prediction.W_8C != prediction.F_C && prediction.W_8C != prediction.S_D) { return false; }
        if (prediction.W_8D != prediction.F_D && prediction.W_8D != prediction.S_C) { return false; }
        if (prediction.W_8E != prediction.F_E && prediction.W_8E != prediction.S_F) { return false; }
        if (prediction.W_8F != prediction.F_F && prediction.W_8F != prediction.S_E) { return false; }
        if (prediction.W_8G != prediction.F_G && prediction.W_8G != prediction.S_H) { return false; }
        if (prediction.W_8H != prediction.F_H && prediction.W_8H != prediction.S_G) { return false; }

        if (prediction.W_4A != prediction.W_8A && prediction.W_4A != prediction.W_8C) { return false; }
        if (prediction.W_4B != prediction.W_8B && prediction.W_4B != prediction.W_8D) { return false; }
        if (prediction.W_4C != prediction.W_8E && prediction.W_4C != prediction.W_8G) { return false; }
        if (prediction.W_4D != prediction.W_8F && prediction.W_4D != prediction.W_8H) { return false; }

        if (prediction.W_2A != prediction.W_4A && prediction.W_2A != prediction.W_4C) { return false; }
        if (prediction.W_2B != prediction.W_4B && prediction.W_2B != prediction.W_4D) { return false; }

        if (prediction.FRST != prediction.W_2A && prediction.FRST != prediction.W_2B) { return false; }

        //For third place:
        // - Finds out the semi final losers and makes sure the third place is one of them
        uint8 L_2A = (prediction.W_2A == prediction.W_4A)?prediction.W_4C:prediction.W_4A;
        uint8 L_2B = (prediction.W_2B == prediction.W_4B)?prediction.W_4D:prediction.W_4B;
        if (prediction.THRD != L_2A && prediction.THRD != L_2B) { return false; }

        if ((prediction.timestamp >= (W_8A_DEADLINE - gap)) && verifyTimestamp) { return false; }

        return true;
    }


    //Compares a Prediction to the Results
    //Returns true if doesn't have differences with any result set in the state
    function isPredictionCurrent(Fixture memory prediction, Fixture memory results) external pure returns (bool) {
        if (results.F_A > 0 && results.F_A != prediction.F_A) { return false; }
        if (results.F_B > 0 && results.F_B != prediction.F_B) { return false; }
        if (results.F_C > 0 && results.F_C != prediction.F_C) { return false; }
        if (results.F_D > 0 && results.F_D != prediction.F_D) { return false; }
        if (results.F_E > 0 && results.F_E != prediction.F_E) { return false; }
        if (results.F_F > 0 && results.F_F != prediction.F_F) { return false; }
        if (results.F_G > 0 && results.F_G != prediction.F_G) { return false; }
        if (results.F_H > 0 && results.F_H != prediction.F_H) { return false; }

        if (results.S_A > 0 && results.S_A != prediction.S_A) { return false; }
        if (results.S_B > 0 && results.S_B != prediction.S_B) { return false; }
        if (results.S_C > 0 && results.S_C != prediction.S_C) { return false; }
        if (results.S_D > 0 && results.S_D != prediction.S_D) { return false; }
        if (results.S_E > 0 && results.S_E != prediction.S_E) { return false; }
        if (results.S_F > 0 && results.S_F != prediction.S_F) { return false; }
        if (results.S_G > 0 && results.S_G != prediction.S_G) { return false; }
        if (results.S_H > 0 && results.S_H != prediction.S_H) { return false; }

        if (results.W_8A > 0 && results.W_8A != prediction.W_8A) { return false; }
        if (results.W_8B > 0 && results.W_8B != prediction.W_8B) { return false; }
        if (results.W_8C > 0 && results.W_8C != prediction.W_8C) { return false; }
        if (results.W_8D > 0 && results.W_8D != prediction.W_8D) { return false; }
        if (results.W_8E > 0 && results.W_8E != prediction.W_8E) { return false; }
        if (results.W_8F > 0 && results.W_8F != prediction.W_8F) { return false; }
        if (results.W_8G > 0 && results.W_8G != prediction.W_8G) { return false; }
        if (results.W_8H > 0 && results.W_8H != prediction.W_8H) { return false; }

        if (results.W_4A > 0 && results.W_4A != prediction.W_4A) { return false; }
        if (results.W_4B > 0 && results.W_4B != prediction.W_4B) { return false; }
        if (results.W_4C > 0 && results.W_4C != prediction.W_4C) { return false; }
        if (results.W_4D > 0 && results.W_4D != prediction.W_4D) { return false; }

        if (results.W_2A > 0 && results.W_2A != prediction.W_2A) { return false; }
        if (results.W_2B > 0 && results.W_2B != prediction.W_2B) { return false; }

        if (results.FRST > 0 && results.FRST != prediction.FRST) { return false; }
        if (results.THRD > 0 && results.THRD != prediction.THRD) { return false; }

        return true;
    }

    //This function is used to update the results by the Oracle
    function stateTransition(Fixture memory results, uint8 n, uint8 value, uint256 timestamp) external pure returns (Fixture memory) {
        if (n == 0) { if (value == 0 || (value >=1 && value <=4 && results.S_A != value && timestamp > GROUP_A_DEADLINE)) { results.F_A = value; } else { revert Invalid(); }}
        if (n == 1)  { if (value == 0 || (value >=1 && value <=4 && results.F_A != value && timestamp > GROUP_A_DEADLINE)) { results.S_A = value; } else { revert Invalid(); }}
        if (n == 2) { if (value == 0 || (value >=5 && value <=8 && results.S_B != value && timestamp > GROUP_B_DEADLINE)) { results.F_B = value; } else { revert Invalid(); }}
        if (n == 3)  { if (value == 0 || (value >=5 && value <=8 && results.F_B != value && timestamp > GROUP_B_DEADLINE)) { results.S_B = value; } else { revert Invalid(); }}
        if (n == 4) { if (value == 0 || (value >=9 && value <=12 && results.S_C != value && timestamp > GROUP_C_DEADLINE)) { results.F_C = value; } else { revert Invalid(); }}
        if (n == 5) { if (value == 0 || (value >=9 && value <=12 && results.F_C != value && timestamp > GROUP_C_DEADLINE)) { results.S_C = value; } else { revert Invalid(); }}
        if (n == 6) { if (value == 0 || (value >=13 && value <=16 && results.S_D != value && timestamp > GROUP_D_DEADLINE)) { results.F_D = value; } else { revert Invalid(); }}
        if (n == 7) { if (value == 0 || (value >=13 && value <=16 && results.F_D != value && timestamp > GROUP_D_DEADLINE)) { results.S_D = value; } else { revert Invalid(); }}
        if (n == 8) { if (value == 0 || (value >=17 && value <=20 && results.S_E != value && timestamp > GROUP_E_DEADLINE)) { results.F_E = value; } else { revert Invalid(); }}
        if (n == 9) { if (value == 0 || (value >=17 && value <=20 && results.F_E != value && timestamp > GROUP_E_DEADLINE)) { results.S_E = value; } else { revert Invalid(); }}
        if (n == 10) { if (value == 0 || (value >=21 && value <=24 && results.S_F != value && timestamp > GROUP_F_DEADLINE)) { results.F_F = value; } else { revert Invalid(); }}
        if (n == 11) { if (value == 0 || (value >=21 && value <=24 && results.F_F != value && timestamp > GROUP_F_DEADLINE)) { results.S_F = value; } else { revert Invalid(); }}
        if (n == 12) { if (value == 0 || (value >=25 && value <=28 && results.S_G != value && timestamp > GROUP_G_DEADLINE)) { results.F_G = value; } else { revert Invalid(); }}
        if (n == 13) { if (value == 0 || (value >=25 && value <=28 && results.F_G != value && timestamp > GROUP_G_DEADLINE)) { results.S_G = value; } else { revert Invalid(); }}
        if (n == 14) { if (value == 0 || (value >=29 && value <=32 && results.S_H != value && timestamp > GROUP_H_DEADLINE)) { results.F_H = value; } else { revert Invalid(); }}
        if (n == 15) { if (value == 0 || (value >=29 && value <=32 && results.F_H != value && timestamp > GROUP_H_DEADLINE)) { results.S_H = value; } else { revert Invalid(); }}

        if (n == 16) { if (value == 0 || (value > 0 && (results.F_A == value || results.S_B == value) && timestamp > W_8A_DEADLINE)) { results.W_8A = value; } else { revert Invalid(); }}
        if (n == 17) { if (value == 0 || (value > 0 && (results.F_B == value || results.S_A == value) && timestamp > W_8B_DEADLINE)) { results.W_8B = value; } else { revert Invalid(); }}
        if (n == 18) { if (value == 0 || (value > 0 && (results.F_C == value || results.S_D == value) && timestamp > W_8C_DEADLINE)) { results.W_8C = value; } else { revert Invalid(); }}
        if (n == 19) { if (value == 0 || (value > 0 && (results.F_D == value || results.S_C == value) && timestamp > W_8D_DEADLINE)) { results.W_8D = value; } else { revert Invalid(); }}
        if (n == 20) { if (value == 0 || (value > 0 && (results.F_E == value || results.S_F == value) && timestamp > W_8E_DEADLINE)) { results.W_8E = value; } else { revert Invalid(); }}
        if (n == 21) { if (value == 0 || (value > 0 && (results.F_F == value || results.S_E == value) && timestamp > W_8F_DEADLINE)) { results.W_8F = value; } else { revert Invalid(); }}
        if (n == 22) { if (value == 0 || (value > 0 && (results.F_G == value || results.S_H == value) && timestamp > W_8G_DEADLINE)) { results.W_8G = value; } else { revert Invalid(); }}
        if (n == 23) { if (value == 0 || (value > 0 && (results.F_H == value || results.S_G == value) && timestamp > W_8H_DEADLINE)) { results.W_8H = value; } else { revert Invalid(); }}

        if (n == 24) { if (value == 0 || (value > 0 && (results.W_8A == value || results.W_8C == value) && timestamp > W_4A_DEADLINE)) { results.W_4A = value; } else { revert Invalid(); }}
        if (n == 25) { if (value == 0 || (value > 0 && (results.W_8B == value || results.W_8D == value) && timestamp > W_4B_DEADLINE)) { results.W_4B = value; } else { revert Invalid(); }}
        if (n == 26) { if (value == 0 || (value > 0 && (results.W_8E == value || results.W_8G == value) && timestamp > W_4C_DEADLINE)) { results.W_4C = value; } else { revert Invalid(); }}
        if (n == 27) { if (value == 0 || (value > 0 && (results.W_8F == value || results.W_8H == value) && timestamp > W_4D_DEADLINE)) { results.W_4D = value; } else { revert Invalid(); }}

        if (n == 28) { if (value == 0 || (value > 0 && (results.W_4A == value || results.W_4C == value) && timestamp > W_2A_DEADLINE)) { results.W_2A = value; } else { revert Invalid(); }}
        if (n == 29) { if (value == 0 || (value > 0 && (results.W_4B == value || results.W_4D == value) && timestamp > W_2B_DEADLINE)) { results.W_2B = value; } else { revert Invalid(); }}

        if (n == 30) {
            if (results.W_4A > 0 && results.W_4B > 0 && results.W_4C > 0 && results.W_4D > 0 && results.W_2A > 0 && results.W_2B > 0 &&
                (results.W_2A == results.W_4A || results.W_2A == results.W_4C) && (results.W_2B == results.W_4B || results.W_2B == results.W_4D)) { 
                uint8 L_2A = (results.W_2A == results.W_4A)?results.W_4C:results.W_4A;
                uint8 L_2B = (results.W_2B == results.W_4B)?results.W_4D:results.W_4B;
                if (value == 0 || (value > 0 && (L_2A == value || L_2B == value) && timestamp > THIRD_DEADLINE)) { results.THRD = value; } else { revert Invalid(); }
            } else { revert Invalid(); }
        }
        if (n == 31){ if (value == 0 || (value > 0 && (results.W_2A == value || results.W_2B == value) && timestamp > FINAL_DEADLINE)) { results.FRST = value; } else { revert Invalid(); }}

        results.timestamp = timestamp;
        return results;
    }

    //This function calculates the points of a Prediction as follows:
    //Group phase corret prediction:         +2 points       Group phase incorrect prediction:            -1 points
    //Round of 16 corret prediction:         +4 points       Round of 16 incorrect prediction:            -2 points
    //Quarter Finals corret prediction:      +8 points       Quarter Finals incorrect prediction:         -4 points
    //Semi Finals corret prediction:        +16 points       Semi Finals incorrect prediction:            -8 points
    //Final & 3rd. Place corret prediction: +32 points       Final & 3rd. Place incorrect prediction:    -16 points
    function calcPredictionPoints(Fixture memory prediction, Fixture memory results, uint256 gap) external pure returns (uint256) {
        uint256 points;

        if (results.F_A > 0 && results.F_A == prediction.F_A && prediction.timestamp <= (GROUP_A_DEADLINE - gap)) { points += 2; }
        if (results.F_B > 0 && results.F_B == prediction.F_B && prediction.timestamp <= (GROUP_B_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_C > 0 && results.F_C == prediction.F_C && prediction.timestamp <= (GROUP_C_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_D > 0 && results.F_D == prediction.F_D && prediction.timestamp <= (GROUP_D_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_E > 0 && results.F_E == prediction.F_E && prediction.timestamp <= (GROUP_E_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_F > 0 && results.F_F == prediction.F_F && prediction.timestamp <= (GROUP_F_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_G > 0 && results.F_G == prediction.F_G && prediction.timestamp <= (GROUP_G_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_H > 0 && results.F_H == prediction.F_H && prediction.timestamp <= (GROUP_H_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_A > 0 && results.S_A == prediction.S_A && prediction.timestamp <= (GROUP_A_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_B > 0 && results.S_B == prediction.S_B && prediction.timestamp <= (GROUP_B_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_C > 0 && results.S_C == prediction.S_C && prediction.timestamp <= (GROUP_C_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_D > 0 && results.S_D == prediction.S_D && prediction.timestamp <= (GROUP_D_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_E > 0 && results.S_E == prediction.S_E && prediction.timestamp <= (GROUP_E_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_F > 0 && results.S_F == prediction.S_F && prediction.timestamp <= (GROUP_F_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_G > 0 && results.S_G == prediction.S_G && prediction.timestamp <= (GROUP_G_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_H > 0 && results.S_H == prediction.S_H && prediction.timestamp <= (GROUP_H_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}

        if (results.W_8A > 0 && results.W_8A == prediction.W_8A && prediction.timestamp <= (W_8A_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8B > 0 && results.W_8B == prediction.W_8B && prediction.timestamp <= (W_8B_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8C > 0 && results.W_8C == prediction.W_8C && prediction.timestamp <= (W_8C_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8D > 0 && results.W_8D == prediction.W_8D && prediction.timestamp <= (W_8D_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8E > 0 && results.W_8E == prediction.W_8E && prediction.timestamp <= (W_8E_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8F > 0 && results.W_8F == prediction.W_8F && prediction.timestamp <= (W_8F_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8G > 0 && results.W_8G == prediction.W_8G && prediction.timestamp <= (W_8G_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8H > 0 && results.W_8H == prediction.W_8H && prediction.timestamp <= (W_8H_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}

        if (results.W_4A > 0 && results.W_4A == prediction.W_4A && prediction.timestamp <= (W_4A_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}
        if (results.W_4B > 0 && results.W_4B == prediction.W_4B && prediction.timestamp <= (W_4B_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}
        if (results.W_4C > 0 && results.W_4C == prediction.W_4C && prediction.timestamp <= (W_4C_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}
        if (results.W_4D > 0 && results.W_4D == prediction.W_4D && prediction.timestamp <= (W_4D_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}

        if (results.W_2A > 0 && results.W_2A == prediction.W_2A && prediction.timestamp <= (W_2A_DEADLINE - gap)) { points += 16; } else { if (points >= 8) { points -= 4; } else { points = 0; }}
        if (results.W_2B > 0 && results.W_2B == prediction.W_2B && prediction.timestamp <= (W_2B_DEADLINE - gap)) { points += 16; } else { if (points >= 8) { points -= 4; } else { points = 0; }}

        if (results.THRD > 0 && results.THRD == prediction.THRD && prediction.timestamp <= (THIRD_DEADLINE - gap)) { points += 32; } else { if (points >= 16) { points -= 4; } else { points = 0; }}
        if (results.FRST > 0 && results.FRST == prediction.FRST && prediction.timestamp <= (FINAL_DEADLINE - gap)) { points += 32; } else { if (points >= 16) { points -= 4; } else { points = 0; }}

        return points;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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