// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./ILevel.sol";
import "./LevelBase.sol";
import "./IPeekABoo.sol";
import "./IStakeManager.sol";

contract Level is
    ILevel,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    LevelBase
{
    function initialize(IPeekABoo _peekaboo) public initializer {
        __Ownable_init();
        __Pausable_init();
        peekaboo = _peekaboo;

        difficultyToEXP[0] = 1;
        difficultyToEXP[1] = 2;
        difficultyToEXP[2] = 4;

        BASE_EXP = 10;
        EXP_GROWTH_RATE1 = 11;
        EXP_GROWTH_RATE2 = 10;
    }

    modifier onlyService() {
        require(
            stakeManager.isService(_msgSender()),
            "Must be a service, don't cheat"
        );
        _;
    }

    function updateExp(
        uint256 tokenId,
        bool won,
        uint256 difficulty
    ) external onlyService {
        uint256 tokenExp = tokenIdToEXP[tokenId];
        uint256 _expRequired = expRequired(tokenId);
        uint256 expGained;
        if (won) {
            expGained = (difficultyToEXP[difficulty] * 4);
        } else {
            expGained = difficultyToEXP[difficulty];
        }
        IPeekABoo peekabooRef = peekaboo;

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

    function expAmount(uint256 tokenId) external view returns (uint256) {
        return tokenIdToEXP[tokenId];
    }

    function expRequired(uint256 tokenId) public returns (uint256) {
        IPeekABoo peekabooRef = peekaboo;
        uint256 levelRequirement = peekabooRef.getTokenTraits(tokenId).level;
        return
            (BASE_EXP * growthRate(levelRequirement)) /
            growthRate2(levelRequirement);
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
    ) external returns (bool) {
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
    ) external onlyOwner {
        difficultyToEXP[0] = easy;
        difficultyToEXP[1] = medium;
        difficultyToEXP[2] = hard;
    }

    function setStakeManager(address _stakeManager) external onlyOwner {
        stakeManager = IStakeManager(_stakeManager);
    }

    function setPeekABoo(address _peekaboo) external onlyOwner {
        peekaboo = IPeekABoo(_peekaboo);
    }

    function getUnlockedTraits(uint256 tokenId, uint256 traitType)
        external
        returns (uint256)
    {
        return unlockedTraits[tokenId][traitType];
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./IPeekABoo.sol";
import "./IStakeManager.sol";

contract LevelBase {
    IPeekABoo public peekaboo;
    IStakeManager public stakeManager;

    uint256 BASE_EXP;
    uint256 EXP_GROWTH_RATE1;
    uint256 EXP_GROWTH_RATE2;

    mapping(uint256 => uint256) public tokenIdToEXP;
    mapping(uint256 => uint256) public difficultyToEXP;
    mapping(uint256 => mapping(uint256 => uint256)) public unlockedTraits;

    event LevelUp(uint256 tokenId);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;

interface IStakeManager {
    function stakePABOnService(
        uint256 tokenId,
        address service,
        address owner
    ) external;

    function isStaked(uint256 tokenId, address service)
        external
        view
        returns (bool);

    function unstakePeekABoo(uint256 tokenId) external;

    function getServices() external view returns (address[] memory);

    function isService(address service) external view returns (bool);

    function initializeEnergy(uint256 tokenId) external;

    function claimEnergy(uint256 tokenId) external;

    function useEnergy(uint256 tokenId, uint256 amount) external;

    function ownerOf(uint256 tokenId) external returns (address);

    function tokensOf(address owner) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPeekABoo is IERC721Upgradeable {
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
    }

    struct GhostMap {
        uint256[10][10] grid;
        int256 gridSize;
        uint256 difficulty;
        bool initialized;
    }

    function devMint(address to, uint256[] memory types) external;

    function mint(uint256[] calldata types, bytes32[] memory proof) external;

    function publicMint(uint256[] calldata types) external payable;

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

    function mintPhase2(
        uint256 tokenId,
        uint256[] memory types,
        uint256 amount,
        uint256 booAmount
    ) external;

    function incrementLevel(uint256 tokenId) external;

    function incrementTier(uint256 tokenId) external;

    function getPhase1Minted() external view returns (uint256 result);

    function getPhase2Minted() external view returns (uint256 result);

    function withdraw() external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./IPeekABoo.sol";
import "./IStakeManager.sol";

interface ILevel {
    function updateExp(
        uint256 tokenId,
        bool won,
        uint256 difficulty
    ) external;

    function expAmount(uint256 tokenId) external view returns (uint256);

    function isUnlocked(
        uint256 tokenId,
        uint256 traitType,
        uint256 traitId
    ) external returns (bool);

    function getUnlockedTraits(uint256 tokenId, uint256 traitType)
        external
        returns (uint256);
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
interface IERC165Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}