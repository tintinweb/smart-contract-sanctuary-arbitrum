// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/token/modular/hybrid/HybridERC20Ops.sol";

contract ViciERC20Opsv2 is HybridERC20Ops {
    function reinit(uint256 _maxSupply) public reinitializer(2) {
        maxSupply = _maxSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/common/OwnerOperator.sol";
import "contracts/impl/AbstractPluginExecutor.sol";
import "contracts/token/modular/IModularViciERC20.sol";
import "contracts/token/modular/IModularERC20Ops.sol";
import "contracts/token/modular/ViciERC20RolesErrorsEvents.sol";

abstract contract HybridERC20OpsBase01 is OwnerOperator, IModularERC20Ops {
    uint256 maxSupply;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

abstract contract HybridERC20OpsBase02 is HybridERC20OpsBase01 {
    mapping(address => uint256) internal lockedAmount;
    mapping(address => uint256) internal releaseDate;

    /**
     * @notice locked airdrops smaller than this amount CANNOT change a previously set lock date.
     * @notice locked airdrops larger than this amount CAN change a previously set lock date.
     * @dev This value SHOULD be large enough to discourage griefing by using tiny airdrops
     *      to set a user's unlock date far into the future
     */
    uint256 public airdropThreshold;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

contract HybridERC20Ops is
    HybridERC20OpsBase02,
    AbstractPluginExecutor,
    ViciERC20RolesErrorsEvents
{
    function parent() public view virtual override returns (IModularViciERC20) {
        return IModularViciERC20(owner());
    }

    function checkPluginManagerPermission(
        address sender
    ) internal view virtual override {
        if (sender != owner() && sender != parent().owner()) {
            revert OwnableUnauthorizedAccount(sender);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IModularERC20Ops).interfaceId;
    }

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize(
        uint256 _maxSupply,
        uint256 _airdropThreshold
    ) public virtual initializer {
        __ERC20Operations_init(_maxSupply, _airdropThreshold);
    }

    function __ERC20Operations_init(
        uint256 _maxSupply,
        uint256 _airdropThreshold
    ) internal onlyInitializing {
        __OwnerOperator_init();
        __ERC20Operations_init_unchained(_maxSupply, _airdropThreshold);
    }

    function __ERC20Operations_init_unchained(
        uint256 _maxSupply,
        uint256 _airdropThreshold
    ) internal onlyInitializing {
        maxSupply = _maxSupply;
        airdropThreshold = _airdropThreshold;
    }

    // @dev see ViciAccess
    modifier notBanned(address account) {
        parent().enforceIsNotBanned(account);
        _;
    }

    // @dev see ViciAccess
    modifier onlyOwnerOrRole(address account, bytes32 role) {
        parent().enforceOwnerOrRole(role, account);
        _;
    }

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns the total maximum possible that can be minted.
     */
    function getMaxSupply() public view virtual override returns (uint256) {
        return maxSupply;
    }

    /**
     * @dev Returns the amount that has been minted so far.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return itemSupply(1);
    }

    /**
     * @dev returns the amount available to be minted.
     * @dev {total available} = {max supply} - {amount minted so far}
     */
    function availableSupply() public view virtual override returns (uint256) {
        return maxSupply - itemSupply(1);
    }

    /**
     * @dev see IERC20
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256 balance) {
        balance = getBalance(account, 1);
    }

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Updates available quantities
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC20Receiver-onERC20Received}, which is called upon a safe
     *      transfer.
     */
    function mint(
        address operator,
        address toAddress,
        uint256 amount
    )
        public
        virtual
        override
        onlyOwner
        notBanned(toAddress)
        pluggable
    {
        if (availableSupply() < amount) {
            revert SoldOut();
        }
        _mint(operator, toAddress, amount);
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
    function _mint(
        address operator,
        address toAddress,
        uint256 amount
    ) internal virtual {
        if (toAddress == address(0)) {
            revert ERC20InvalidReceiver(toAddress);
        }

        doTransfer(operator, address(0), toAddress, 1, amount);
    }

    /**
     * @dev see IERC20
     */
    function transfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 amount
    )
        public
        virtual
        override
        onlyOwner
        notBanned(operator)
        notBanned(fromAddress)
        notBanned(toAddress)
        pluggable
    {
        if (toAddress == address(0)) {
            revert ERC20InvalidReceiver(toAddress);
        }
        if (fromAddress == address(0)) {
            revert ERC20InvalidSender(fromAddress);
        }
        doTransfer(operator, fromAddress, toAddress, 1, amount);
    }

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     */
    function burn(
        address operator,
        address fromAddress,
        uint256 amount
    )
        public
        virtual
        override
        onlyOwner
        pluggable
    {
        _burn(operator, fromAddress, amount);
    }

    function _burn(
        address operator,
        address fromAddress,
        uint256 amount
    ) internal {
        if (fromAddress == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        doTransfer(operator, fromAddress, address(0), 1, amount);
    }

    /* ################################################################
     * Approvals / Allowances
     * ##############################################################*/

    /**
     * @dev see IERC20
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return allowance(owner, spender, 1);
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 amount
    )
        public
        virtual
        override
        onlyOwner
        notBanned(owner)
        notBanned(spender)
        pluggable
    {
        approve(owner, spender, 1, amount);
    }

    /**
     * @dev see {IERC20Operations-recoverSanctionedAssets}
     */
    function recoverSanctionedAssets(
        address operator,
        address fromAddress,
        address toAddress
    )
        public
        virtual
        override
        onlyOwner
        notBanned(toAddress)
        pluggable
        returns (uint256 amount)
    {
        if (
            !parent().isBanned(fromAddress) &&
            !parent().isSanctioned(fromAddress)
        ) {
            revert InvalidSanctionedWallet(fromAddress);
        }

        amount = balanceOf(fromAddress);
        approve(fromAddress, operator, 1, amount);
        doTransfer(operator, fromAddress, toAddress, 1, amount);
    }

    /* ################################################################
     * Utility Coin Functions
     * ##############################################################*/

    /**
     *  @dev see {IERC20UtilityOperations-airdropTimelockedTokens}.
     */
    function airdropTimelockedTokens(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 amount,
        uint256 release
    )
        public
        virtual
        onlyOwner
        pluggable
    {
        transfer(operator, fromAddress, toAddress, amount);
        uint256 currentLockedBalance = lockedBalanceOf(toAddress);
        uint256 currentLockRelease = releaseDate[toAddress];
        // unlock date can move forward if amount at least 1K

        if (currentLockedBalance == 0) {
            releaseDate[toAddress] = release;
            lockedAmount[toAddress] = amount;
        } else if (
            amount >= airdropThreshold && release >= currentLockRelease
        ) {
            lockedAmount[toAddress] = currentLockedBalance + amount;

            releaseDate[toAddress] = release;
            emit LockUpdated(toAddress, currentLockRelease, release);
        } else {
            lockedAmount[toAddress] += amount;
        }
    }

    /**
     *  @dev see {IERC20UtilityOperations-unlockLockedTokens}.
     */
    function unlockLockedTokens(
        address /* operator */,
        address account,
        uint256 unlockAmount
    )
        public
        virtual
        onlyOwner
        pluggable
    {
        if (unlockAmount >= lockedAmount[account]) {
            lockedAmount[account] = 0;
        } else {
            lockedAmount[account] -= unlockAmount;
        }
    }

    /**
     *  @dev see {IERC20UtilityOperations-updateTimelocks}.
     */
    function updateTimelocks(
        address /* operator */,
        uint256 release,
        address[] calldata addresses
    )
        public
        virtual
        onlyOwner
        pluggable
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 previousRelease = lockReleaseDate(addresses[i]);
            if (previousRelease > 0) {
                releaseDate[addresses[i]] = release;
                emit LockUpdated(addresses[i], previousRelease, release);
            }
        }
    }

    /**
     *  @dev see {IERC20UtilityOperations-lockedBalanceOf}.
     */
    function lockedBalanceOf(
        address account
    ) public view virtual returns (uint256) {
        if (_currentTimestamp() > releaseDate[account]) {
            return 0;
        }
        return lockedAmount[account];
    }

    /**
     *  @dev see {IERC20UtilityOperations-lockReleaseDate}.
     */
    function lockReleaseDate(
        address account
    ) public view virtual returns (uint256) {
        if (lockedBalanceOf(account) == 0) {
            return 0;
        }
        return releaseDate[account];
    }

    /**
     *  @dev see {IERC20UtilityOperations-unlockedBalanceOf}.
     */
    function unlockedBalanceOf(
        address account
    ) public view virtual returns (uint256) {
        uint256 acctBalance = balanceOf(account);
        if (_currentTimestamp() >= releaseDate[account]) {
            return acctBalance;
        }
        return
            (lockedAmount[account] > acctBalance)
                ? 0
                : acctBalance - lockedAmount[account];
    }

    function _checkLocks(
        address fromAddress,
        uint256 transferAmount
    ) internal view virtual {
        if (
            _currentTimestamp() < releaseDate[fromAddress] &&
            lockedAmount[fromAddress] > 0
        ) {
            if (
                balanceOf(fromAddress) <
                transferAmount + lockedAmount[fromAddress]
            ) {
                revert ERC20InsufficientBalance(
                    fromAddress,
                    unlockedBalanceOf(fromAddress),
                    transferAmount
                );
            }
        }
    }

    /**
     * @dev see {IERC20-transfer}.
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) public virtual override(OwnerOperator, IOwnerOperator) pluggable {
        _checkLocks(fromAddress, amount);

        OwnerOperator.doTransfer(
            operator,
            fromAddress,
            toAddress,
            thing,
            amount
        );
    }

    /**
     *  @dev see {ERC20UtilityOperations-recoverMisplacedTokens}.
     */
    function recoverMisplacedTokens(
        address operator,
        address fromAddress,
        address toAddress
    )
        public
        virtual
        onlyOwner
        notBanned(toAddress)
        pluggable
        returns (uint256 amount)
    {
        if (!parent().hasRole(LOST_WALLET, fromAddress)) {
            revert InvalidLostWallet(fromAddress);
        }
        if (toAddress == address(0)) {
            revert ERC20InvalidReceiver(toAddress);
        }

        lockedAmount[fromAddress] = 0;
        releaseDate[fromAddress] = 0;

        amount = balanceOf(fromAddress);
        approve(fromAddress, operator, 1, amount);
        doTransfer(operator, fromAddress, toAddress, 1, amount);
    }

    function _currentTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/structs/EnumerableSet.sol";

import "contracts/access/ViciOwnable.sol";
import "contracts/lib/EnumerableUint256Set.sol";
import "contracts/common/IOwnerOperator.sol";

/**
 * @title Owner Operator
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This contract manages ownership of items, and allows an owner to delegate
 *     other addresses as their agent.
 * @dev Concrete subclasses SHOULD add functionality to support a specific type
 *     of item.
 * @dev It can be used to manage ownership of various types of tokens, such as
 *     ERC20, ERC677, ERC721, ERC777, and ERC1155.
 * @dev For coin-type tokens such as ERC20, ERC677, or ERC721, always pass `1`
 *     as `thing`. Comments that refer to the use of this library to manage
 *     these types of tokens will use the shorthand `COINS:`.
 * @dev For NFT-type tokens such as ERC721, always pass `1` as the `amount`.
 *     Comments that refer to the use of this library to manage these types of
 *     tokens will use the shorthand `NFTS:`.
 * @dev For semi-fungible tokens such as ERC1155, use `thing` as the token ID
 *     and `amount` as the number of tokens with that ID.
 */

abstract contract OwnerOperator is ViciOwnable, IOwnerOperator {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    /*
     * For ERC20 / ERC777, there will only be one item
     */
    EnumerableUint256Set.Uint256Set allItems;

    EnumerableSet.AddressSet allOwners;

    /*
     * amount of each item
     * mapping(itemId => amount)
     * for ERC721, amount will be 1 or 0
     * for ERC20 / ERC777, there will only be one key
     */
    mapping(uint256 => uint256) amountOfItem;

    /*
     * which items are owned by which owners?
     * for ERC20 / ERC777, the result will have 0 or 1 elements
     */
    mapping(address => EnumerableUint256Set.Uint256Set) itemIdsByOwner;

    /*
     * which owners hold which items?
     * For ERC20 / ERC777, there will only be 1 key
     * For ERC721, result will have 0 or 1 elements
     */
    mapping(uint256 => EnumerableSet.AddressSet) ownersByItemIds;

    /*
     * for a given item id, what is the address's balance?
     * mapping(itemId => mapping(owner => amount))
     * for ERC20 / ERC777, there will only be 1 key
     * for ERC721, result is 1 or 0
     */
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(uint256 => address)) itemApprovals;

    /*
     * for a given owner, how much of each item id is an operator allowed to control?
     */
    mapping(address => mapping(uint256 => mapping(address => uint256))) allowances;
    mapping(address => mapping(address => bool)) operatorApprovals;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function __OwnerOperator_init() internal onlyInitializing {
        __Ownable_init();
        __OwnerOperator_init_unchained();
    }

    function __OwnerOperator_init_unchained() internal onlyInitializing {}

    /**
     * @dev revert if the item does not exist
     */
    modifier itemExists(uint256 thing) {
        require(exists(thing), "invalid item");
        _;
    }

    /**
     * @dev revert if the user is the null address
     */
    modifier validUser(address user) {
        require(user != address(0), "invalid user");
        _;
    }

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(
        uint256 thing
    ) public view virtual override itemExists(thing) {}

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(uint256 thing) public view virtual override returns (bool) {
        return amountOfItem[thing] > 0;
    }

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() public view virtual override returns (uint256) {
        return allOwners.length();
    }

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(
        uint256 index
    ) public view virtual override returns (address) {
        require(allOwners.length() > index, "owner index out of bounds");
        return allOwners.at(index);
    }

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() public view virtual override returns (uint256) {
        return allItems.length();
    }

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(
        uint256 index
    ) public view virtual override returns (uint256) {
        require(allItems.length() > index, "item index out of bounds");
        return allItems.at(index);
    }

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(
        uint256 thing
    ) public view virtual override returns (uint256) {
        return amountOfItem[thing];
    }

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function getBalance(
        address owner,
        uint256 thing
    ) public view virtual override validUser(owner) returns (uint256) {
        return balances[thing][owner];
    }

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(
        address user
    ) public view virtual override validUser(user) returns (uint256[] memory) {
        return itemIdsByOwner[user].asList();
    }

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(
        address owner
    ) public view virtual override validUser(owner) returns (uint256) {
        return itemIdsByOwner[owner].length();
    }

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override validUser(owner) returns (uint256) {
        require(
            itemIdsByOwner[owner].length() > index,
            "item index out of bounds"
        );
        return itemIdsByOwner[owner].at(index);
    }

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(
        uint256 thing
    ) public view virtual override itemExists(thing) returns (uint256) {
        return ownersByItemIds[thing].length();
    }

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(
        uint256 thing,
        uint256 index
    ) public view virtual override itemExists(thing) returns (address owner) {
        require(
            ownersByItemIds[thing].length() > index,
            "owner index out of bounds"
        );
        return ownersByItemIds[thing].at(index);
    }

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) public virtual override onlyOwner {
        // can't mint and burn in same transaction
        require(
            fromAddress != address(0) || toAddress != address(0),
            "invalid transfer"
        );

        // can't transfer nothing
        require(amount > 0, "invalid transfer");

        if (fromAddress == address(0)) {
            // minting
            allItems.add(thing);
            amountOfItem[thing] += amount;
        } else {
            enforceItemExists(thing);
            if (operator != fromAddress) {
                require(
                    _checkApproval(operator, fromAddress, thing, amount),
                    "not authorized"
                );
                uint256 currentAllowance = allowances[fromAddress][thing][
                    operator
                ];
                if (
                    currentAllowance > 0 &&
                    currentAllowance != type(uint256).max
                ) {
                    allowances[fromAddress][thing][operator] -= amount;
                }
            }
            require(
                balances[thing][fromAddress] >= amount,
                "insufficient balance"
            );

            itemApprovals[fromAddress][thing] = address(0);

            if (fromAddress == toAddress) return;

            balances[thing][fromAddress] -= amount;
            if (balances[thing][fromAddress] == 0) {
                allOwners.remove(fromAddress);
                ownersByItemIds[thing].remove(fromAddress);
                itemIdsByOwner[fromAddress].remove(thing);
                if (itemIdsByOwner[fromAddress].length() == 0) {
                    delete itemIdsByOwner[fromAddress];
                }
            }
        }

        if (toAddress == address(0)) {
            // burning
            amountOfItem[thing] -= amount;
            if (amountOfItem[thing] == 0) {
                allItems.remove(thing);
                delete ownersByItemIds[thing];
            }
        } else {
            allOwners.add(toAddress);
            itemIdsByOwner[toAddress].add(thing);
            ownersByItemIds[thing].add(toAddress);
            balances[thing][toAddress] += amount;
        }
    }

    /* ################################################################
     * Allowances / Approvals
     * ##############################################################*/

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) public view virtual override {
        require(
            balances[thing][fromAddress] >= amount &&
                _checkApproval(operator, fromAddress, thing, amount),
            "not authorized"
        );
    }

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) public view virtual override returns (bool) {
        return _checkApproval(operator, fromAddress, thing, amount);
    }

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(
        address fromAddress,
        address operator
    ) public view virtual override returns (bool) {
        return operatorApprovals[fromAddress][operator];
    }

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        address fromAddress,
        address operator,
        bool approved
    ) public override onlyOwner validUser(fromAddress) validUser(operator) {
        require(operator != fromAddress, "approval to self");
        operatorApprovals[fromAddress][operator] = approved;
    }

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        address fromAddress,
        address operator,
        uint256 thing
    ) public view virtual override returns (uint256) {
        return allowances[fromAddress][thing][operator];
    }

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    )
        public
        virtual
        override
        onlyOwner
        validUser(fromAddress)
        validUser(operator)
    {
        require(operator != fromAddress, "approval to self");
        allowances[fromAddress][thing][operator] = amount;
    }

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(
        address fromAddress,
        uint256 thing
    ) public view virtual override returns (address) {
        require(amountOfItem[thing] > 0);
        return itemApprovals[fromAddress][thing];
    }

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        address fromAddress,
        address operator,
        uint256 thing
    ) public virtual override onlyOwner validUser(fromAddress) {
        require(operator != fromAddress, "approval to self");
        require(ownersByItemIds[thing].contains(fromAddress));
        itemApprovals[fromAddress][thing] = operator;
    }

    function _checkApproval(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) internal view virtual returns (bool) {
        return (operator == fromAddress ||
            operatorApprovals[fromAddress][operator] ||
            itemApprovals[fromAddress][thing] == operator ||
            allowances[fromAddress][thing][operator] >= amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.24;

import "contracts/common/ViciContext.sol";
import "contracts/access/AccessEventsErrors.sol";

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
 *
 * @dev This contract is a direct copy of OpenZeppelin's OwnableUpgradeable, 
 * moved here, renamed, and modified to use our Context and Initializable 
 * contracts so we don't have to deal with incompatibilities between OZ's
 * contracts and contracts-upgradeable packages.
 */
abstract contract ViciOwnable is ViciContext, AccessEventsErrors {
    address private _owner;

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
        if(owner() != _msgSender()) revert OwnableUnauthorizedAccount(_msgSender());
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
        if(newOwner == address(0)) {
            revert OwnableInvalidOwner(newOwner);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.24;
import "contracts/common/ViciInitializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * @dev This contract is a direct copy of OpenZeppelin's ContextUpgradeable, 
 * moved here, renamed, and modified to use our Initializable interface so we 
 * don't have to deal with incompatibilities between OZ'` contracts and 
 * contracts-upgradeable `
 */
abstract contract ViciContext is ViciInitializable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.24;

import "contracts/lib/ViciAddressUtils.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
 *
 * @dev This contract is a direct copy of OpenZeppelin's InitializableUpgradeable,
 * moved here, renamed, and modified to use our AddressUtils library so we
 * don't have to deal with incompatibilities between OZ'` contracts and
 * contracts-upgradeable `
 */
abstract contract ViciInitializable {
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
            (isTopLevelCall && _initialized < 1) ||
                (!ViciAddressUtils.isContract(address(this)) && _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.24;

/**
 * @dev Collection of functions related to the address type
 *
 * @dev This contract is a direct copy of OpenZeppelin's AddressUpgradeable, 
 * moved here and renamed so we don't have to deal with incompatibilities 
 * between OZ'` contracts and contracts-upgradeable `
 */
library ViciAddressUtils {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.24;

interface AccessEventsErrors {
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);


    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    error BannedAccount(address account);

    error OFACSanctionedAccount(address account);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /**
     * @notice Emitted when a new administrator is added.
     */
    event AdminAddition(address indexed admin);

    /**
     * @notice Emitted when an administrator is removed.
     */
    event AdminRemoval(address indexed admin);

    /**
     * @notice Emitted when a resource is registered.
     */
    event ResourceRegistration(address indexed resource);

    /**
     * @notice Emitted when `newAdminRole` is set globally as ``role``'s admin
     * role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {GlobalRoleAdminChanged} not being emitted signaling this.
     */
    event GlobalRoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @notice Emitted when `account` is granted `role` globally.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event GlobalRoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Emitted when `account` is revoked `role` globally.
     * @notice `account` will still have `role` where it was granted
     * specifically for any resources
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event GlobalRoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Enumerable Uint256 Set
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 */
library EnumerableUint256Set {
    struct Uint256Set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint256Set storage _set, uint256 _value) internal view returns (bool) {
        return _set.indexes[_value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint256Set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Uint256Set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index];
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            _set.values.push(_value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            _set.indexes[_value] = _set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = _set.indexes[_value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _set.values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = _set.values[lastIndex];

                // Move the last value to the index where the value to delete is
                _set.values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                _set.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            _set.values.pop();

            // Delete the index for the deleted slot
            delete _set.indexes[_value];

            return true;
        } else {
            return false;
        }
    }

    function asList(Uint256Set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Owner Operator Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev public interface for the Owner Operator contract
 */
interface IOwnerOperator {

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(uint256 thing) external view;

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(uint256 thing) external view returns (bool);

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() external view returns (uint256);

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(uint256 index) external view returns (address);

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() external view returns (uint256);

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(uint256 index) external view returns (uint256);

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(uint256 thing) external view returns (uint256);

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function getBalance(address owner, uint256 thing)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(address user) external view returns (uint256[] memory);

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(address owner) external view returns (uint256);

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(uint256 thing) external view returns (uint256);

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(uint256 thing, uint256 index)
        external
        view
        returns (address owner);

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) external;

    /* ################################################################
     * Allowances / Approvals
     * ##############################################################*/

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view;

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view returns (bool);

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(address fromAddress, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        address fromAddress,
        address operator,
        bool approved
    ) external;

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        address fromAddress,
        address operator,
        uint256 thing
    ) external view returns (uint256);

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    ) external;

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(address fromAddress, uint256 thing)
        external
        view
        returns (address);

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        address fromAddress,
        address operator,
        uint256 thing
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/structs/EnumerableSet.sol";
import "contracts/lib/ViciAddressUtils.sol";
import "contracts/interfaces/IPluginIntrospection.sol";
import "contracts/interfaces/ISimplePlugin.sol";
import "contracts/interfaces/ISimplePluginExecutor.sol";
import "contracts/interfaces/SimplePluginConstants.sol";

/**
 * @title Abstract Plugin Executor
 * @author Josh Davis
 * @notice Provides functionlity that any plugin executor would need.
 */
abstract contract AbstractPluginExecutor is
    ISimplePluginExecutor,
    IPluginIntrospection
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ViciAddressUtils for address;

    mapping(address => bool) public installedPlugins;

    /**
     * @dev key = selector, value is the set of plugins that validate the function.
     */
    mapping(bytes4 => EnumerableSet.AddressSet) validators;

    /**
     * @dev key = selector, value is the set of plugins that post-validate the function.
     */
    mapping(bytes4 => EnumerableSet.AddressSet) postops;

    /**
     * @dev key = selector, value is plugin that executes the function.
     */
    mapping(bytes4 => address) executors;

    /**
     * @dev key = interfaceId, value is plugin that provides the implementation.
     */
    mapping(bytes4 => address) public supportedInterfaces;

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            supportedInterfaces[interfaceId] != address(0) ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(ISimplePluginExecutor).interfaceId;
    }

    /* ################################################################
     * Modifiers
     * ##############################################################*/

    /**
     * @notice make sure only authorized users are monkeying with your plugins
     */
    modifier onlyPluginManager() {
        checkPluginManagerPermission(msg.sender);
        _;
    }

    /**
     * @notice for functions that can only be used as a callback from an installed plugin
     */
    modifier onlyPlugin() {
        if (!installedPlugins[msg.sender]) {
            revert CallerIsNotPlugin();
        }
        _;
    }

    /**
     * @notice for functions that cannot call into installed plugins
     */
    modifier notToPlugin(address target) {
        if (installedPlugins[target]) {
            revert IllegalCallToPlugin();
        }
        _;
    }

    /**
     * @notice makes it possible for public or external functions defined in your contact to be validated and 
     *      post-validated by a plugin.
     * @dev functions that use this SHOULD be external.
     */
    modifier pluggable() {
        Message memory _msg = buildMessage();

        _validate(_msg);
        _;
        _postExec(_msg);
    }

    /**
     * @notice makes it possible for private or internal functions defined in your contact to be validated and 
     *      post-validated by a plugin.
     * @param func the selector for the private or internal function
     */
    modifier internalPluggable(bytes4 func) {
        Message memory _msg = buildMessage();
        _msg.sig = func;

        _validate(_msg);
        _;
        _postExec(_msg);
    }

    /**
     * @notice subclasses MUST implement this to ensure only authorized users can add and remove plugins.
     */
    function checkPluginManagerPermission(address caller) internal view virtual;

    /**
     * @notice sublclasses MAY implement this before allowing a plugin to have additional access to its functions.
     *  See `executeFromPlugin`
     * @param plugin the plugin calling back into this contract
     * @param func the function it's trying to call
     */
    function checkPluginInternalAccessAllowed(
        address plugin,
        bytes4 func
    ) internal view virtual {}

    /**
     * @notice sublclasses MAY implement this before allowing a plugin to cause this contract to make an external call.
     * @param plugin the plugin
     * @param target the contract it wants you to call
     * @param func the function it wants you to call
     * @param netValue the matic/ether/etc. it wants you to send
     */
    function checkPluginExternalAccessAllowed(
        address plugin,
        address target,
        bytes4 func,
        uint256 netValue
    ) internal view virtual {}

    /* ################################################################
     * Introspection
     * ##############################################################*/

    /// @inheritdoc IPluginIntrospection
    function getFunctionInstrumentation(
        bytes4 func
    ) public view override returns (InstrumentedFunction memory) {
        return
            InstrumentedFunction(
                func,
                validators[func].values(),
                executors[func],
                postops[func].values()
            );
    }

    /// @inheritdoc IPluginIntrospection
    function getValidators(
        bytes4 func
    ) public view override returns (address[] memory) {
        return validators[func].values();
    }

    /// @inheritdoc IPluginIntrospection
    function getExectuor(bytes4 func) public view override returns (address) {
        return executors[func];
    }

    /// @inheritdoc IPluginIntrospection
    function getPostops(
        bytes4 func
    ) public view override returns (address[] memory) {
        return postops[func].values();
    }

    /* ################################################################
     * Installation
     * ##############################################################*/

    /**
     * @notice Uninstalls `oldPlugin`, then installs `newPlugin`
     * @param oldPlugin  the plugin to be uninstalled
     * @param newPlugin the plugin to be installed
     * @dev see `installSimplePlugin()`, `uninstallSimplePlugin()`
     */
    function replaceSimplePlugin(
        address oldPlugin,
        bytes calldata pluginUninstallData,
        address newPlugin,
        bytes calldata pluginInstallData,
        bool force
    ) public virtual override onlyPluginManager {
        _doPluginUninstall(oldPlugin, pluginUninstallData, force);
        _doPluginInstall(newPlugin, pluginInstallData);
    }

    /**
     * @notice installs a new plugin
     * @param plugin The address of the plugin to be installed
     * @dev emits SimplePluginInstalled
     * @dev reverts with PluginAlreadyInstalled if the plugin is already installed
     * @dev reverts with InvalidPlugin if the address does not implement ISimplePlugin
     * @dev reverts with ExecutePluginAlreadySet if there is already an execution plugin for the selector
     *
     * Requirements:
     * - Caller MUST have permission to install plugins
     * - Subclasses MAY add requirements by overriding `_doAdditionalInstallValidation()`
     */
    function installSimplePlugin(
        address plugin,
        bytes calldata pluginInstallData
    ) public virtual override onlyPluginManager {
        _doPluginInstall(plugin, pluginInstallData);
    }

    function _doPluginInstall(
        address plugin,
        bytes calldata pluginInstallData
    ) internal {
        if (installedPlugins[plugin]) {
            revert PluginAlreadyInstalled();
        }

        ISimplePlugin p = ISimplePlugin(plugin);
        if (!p.supportsInterface(type(ISimplePlugin).interfaceId)) {
            revert InvalidPlugin("Not ISimplePlugin");
        }
        _doAdditionalInstallValidation(plugin);

        _setupInterfaces(p);
        _setupExecutes(p);
        _setupValidators(plugin, p.validates(), validators);
        _setupValidators(plugin, p.postExecs(), postops);

        installedPlugins[plugin] = true;
        p.onInstall(pluginInstallData);

        emit SimplePluginInstalled(plugin);
    }

    function _setupInterfaces(ISimplePlugin plugin) internal virtual {
        bytes4[] memory interfaceIds = plugin.providedInterfaces();
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            bytes4 interfaceId = interfaceIds[i];
            if (supportedInterfaces[interfaceId] != address(0)) {
                revert ExecutePluginAlreadySet(
                    interfaceId,
                    supportedInterfaces[interfaceId]
                );
            }

            supportedInterfaces[interfaceId] = address(plugin);
        }
    }

    function _setupExecutes(ISimplePlugin plugin) internal virtual {
        bytes4[] memory funcs = plugin.executes();
        for (uint256 i = 0; i < funcs.length; i++) {
            bytes4 func = funcs[i];
            if (executors[func] != address(0)) {
                revert ExecutePluginAlreadySet(func, executors[func]);
            }

            executors[func] = address(plugin);
        }
    }

    function _setupValidators(
        address plugin,
        bytes4[] memory funcs,
        mapping(bytes4 => EnumerableSet.AddressSet) storage plugins
    ) internal virtual {
        for (uint256 i = 0; i < funcs.length; i++) {
            plugins[funcs[i]].add(plugin);
        }
    }

    function _doAdditionalInstallValidation(
        address plugin
    ) internal view virtual {}

    /* ################################################################
     * Uninstallation
     * ##############################################################*/

    /**
     * @notice Uninstalls a plugin
     * @notice Uninstalling a plugin that defines an execute selector will cause calls to that function to fail.
     * @param plugin the plugin to be removed
     * @dev emits SimplePluginUninstalled
     * @dev reverts with PluginNotInstalled if the plugin is not installed
     *
     * Requirements:
     * - Caller MUST have permission to install plugins
     * - Subclasses MAY add requirements by overriding `_doAdditionalUninstallValidation()`
     */
    function uninstallSimplePlugin(
        address plugin,
        bytes calldata pluginUninstallData
    ) public virtual override onlyPluginManager {
        _doPluginUninstall(plugin, pluginUninstallData, false);
    }

    function forceUninstallSimplePlugin(
        address plugin,
        bytes calldata pluginUninstallData
    ) public virtual override onlyPluginManager {
        _doPluginUninstall(plugin, pluginUninstallData, true);
    }

    function removePluginSelectorsAndInterfaces(
        address plugin,
        bytes4[] calldata interfaces,
        bytes4[] calldata selectors
    ) public virtual override onlyPluginManager {
        _teardownInterfaces(plugin, interfaces);
        _teardownExecutes(plugin, selectors);
        _teardownValidators(plugin, selectors, validators);
        _teardownValidators(plugin, selectors, postops);
    }

    function _doPluginUninstall(
        address plugin,
        bytes calldata pluginUninstallData,
        bool force
    ) internal {
        if (!installedPlugins[plugin] && !force) {
            revert PluginNotInstalled();
        }
        _doAdditionalUninstallValidation(plugin);

        ISimplePlugin p = ISimplePlugin(plugin);

        _teardownInterfaces(plugin, p.providedInterfaces());
        _teardownExecutes(plugin, p.executes());
        _teardownValidators(plugin, p.validates(), validators);
        _teardownValidators(plugin, p.postExecs(), postops);

        installedPlugins[plugin] = false;

        if (force) {
            p.onUninstall(pluginUninstallData);
        } else {
            try p.onUninstall(pluginUninstallData) {} catch Error(
                string memory reason
            ) {
                emit ErrorInPluginUninstall(bytes(reason));
            } catch (bytes memory reason) {
                emit ErrorInPluginUninstall(reason);
            }
        }

        emit SimplePluginUninstalled(plugin);
    }

    function _teardownInterfaces(
        address plugin,
        bytes4[] memory interfaceIds
    ) internal virtual {
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (supportedInterfaces[interfaceIds[i]] == plugin)
                supportedInterfaces[interfaceIds[i]] = address(0);
        }
    }

    function _teardownExecutes(
        address plugin,
        bytes4[] memory funcs
    ) internal virtual {
        for (uint256 i = 0; i < funcs.length; i++) {
            if (executors[funcs[i]] == plugin) executors[funcs[i]] = address(0);
        }
    }

    function _teardownValidators(
        address plugin,
        bytes4[] memory funcs,
        mapping(bytes4 => EnumerableSet.AddressSet) storage plugins
    ) internal virtual {
        for (uint256 i = 0; i < funcs.length; i++) {
            plugins[funcs[i]].remove(plugin);
        }
    }

    function _doAdditionalUninstallValidation(
        address plugin
    ) internal view virtual {}

    /* ################################################################
     * Execution
     * ##############################################################*/

    function buildMessage() internal virtual returns (Message memory) {
        return Message(msg.data, msg.sender, msg.sig, msg.value);
    }

    /**
     * @notice Execute a call from a plugin through the parent contract.
     * @dev Permissions must be granted to the calling plugin for the call to go through.
     * @param data The calldata to send to the parent contract.
     * @return result The return data from the call.
     *
     * Requirements:
     * - caller MUST be an installed plugin
     * - subclasses MAY add addtional requirements by overriding `checkPluginInternalAccessAllowed`
     */
    function executeFromPlugin(
        bytes calldata data
    ) public payable virtual override onlyPlugin returns (bytes memory result) {
        checkPluginInternalAccessAllowed(msg.sender, msg.sig);
        result = address(this).functionCall(data);
    }

    /**
     * @notice Execute a call from a plugin to a non-plugin address.
     * @param target The address to be called.
     * @param value The value to send with the call.
     * @param data The calldata to send to the target.
     * @return The return data from the call.
     *
     * Requirements:
     * - caller MUST be an installed plugin
     * - `target` MUST NOT be an installed plugin
     * - subclasses MAY add addtional requirements by overriding `checkPluginExternalAccessAllowed`
     */
    function executeFromPluginExternal(
        address target,
        uint256 value,
        bytes calldata data
    )
        public
        payable
        virtual
        override
        onlyPlugin
        notToPlugin(target)
        returns (bytes memory)
    {
        bytes4 func = bytes4(data[:4]);
        uint256 netValue = (msg.value > value) ? msg.value - value : 0;
        checkPluginExternalAccessAllowed(msg.sender, target, func, netValue);
        return target.functionCallWithValue(data, value);
    }

    function _validate(
        Message memory _msg
    ) internal virtual returns (bytes memory result) {
        if (validators[_msg.sig].length() == 0) return TRUE;

        uint256 pluginCount = validators[_msg.sig].length();
        for (uint256 i = 0; i < pluginCount; i++) {
            result = ISimplePlugin(validators[_msg.sig].at(i)).beforeHook(_msg);
        }
    }

    function _postExec(
        Message memory _msg
    ) internal virtual returns (bytes memory result) {
        if (postops[_msg.sig].length() == 0) return TRUE;

        uint256 pluginCount = postops[_msg.sig].length();
        for (uint256 i = 0; i < pluginCount; i++) {
            result = ISimplePlugin(postops[_msg.sig].at(i)).afterHook(_msg);
        }
    }

    function _execute(
        Message memory _msg
    ) internal virtual returns (bytes memory) {
        return ISimplePlugin(executors[_msg.sig]).execute(_msg);
    }

    /**
     * @dev This is where the magic happens.
     * @dev If the first 4 bytes received are in the executors mapping, then  that plugin's execute function is called.
     * @dev If it doesn't match anything, then it reverts with NoSuchMethodError
     */
    fallback(bytes calldata) external payable returns (bytes memory result) {
        Message memory _msg = buildMessage();
        if (executors[_msg.sig] == address(0)) revert NoSuchMethodError();

        _validate(_msg);
        result = _execute(_msg);
        _postExec(_msg);
    }

    receive() external payable virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct InstrumentedFunction {
    // The function selector
    bytes4 func;
    // The plugins that run before the function
    address[] validators;
    // The plugin that provides the function
    address executor;
    // The plugins that run after the function
    address[] postops;
}

interface IPluginIntrospection {
    /**
     * @notice returns information about installed plugins that provide or modify a function 
     * @param func the function selector
     */
    function getFunctionInstrumentation(
        bytes4 func
    ) external view returns (InstrumentedFunction memory);

    /**
     * @notice returns the addressess of installed plugins that run before a function
     * @param func the function selector
     */
    function getValidators(
        bytes4 func
    ) external view returns (address[] memory);

    /**
     * @notice returns the address of the installed plugin that provides a function
     * @param func the function selector
     */
    function getExectuor(bytes4 func) external view returns (address);

    /**
     * @notice returns the addressess of installed plugins that run after a function
     * @param func the function selector
     */
    function getPostops(bytes4 func) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/introspection/IERC165.sol";

/**
 * @title Simple Plugin Interface
 * @author Josh Davis
 * @dev A plugin has three options for intercepting a function call: validation, execution, and post-validation.
 * @dev If a plugin validates a function, then the provided validation code runs before the function executes.
 * @dev If a plugin post-validates a function, then the provided validation code runs after the function executes.
 * @dev If a plugin executes a function, that means the plugin provides the implementation of the fuction.
 * @dev The selectors for the function calls a plugin will intercept are given by `validates()`, `executes()`, 
 *     and `postExecs()`.
 * @dev A Plugin Executor may have many plugins that validate or post validate a given function, but only one 
 *     that executes a function.
 * @dev Plugins may validate or post-validate functions provided by other plugins.
 * @dev If the function to be validated doesn't call  `beforeHook()` or `postExec()`, then the plugin's 
 *     validation will not run. See AbstractPluginExecutor#pluggable modifier.
 * @dev If a function to be executed is already defined by the Plugin Executor, that verion will run and the 
 *     plugin version will be ignored.
 */

struct Message {
    bytes data; // original ABI-encoded function call
    address sender; // original message sender
    bytes4 sig; // function selector
    uint256 value; // amount of eth/matic sent with the transaction, if any
}

interface ISimplePlugin is IERC165 {
    /**
     * @notice called by the plugin executor when the plugin is installed 
     * @param data implementation-specific data required to install and configure
     *      the plugin
     */
    function onInstall(bytes calldata data) external;

    /**
     * @notice called by the plugin executor when the plugin is uninstalled 
     * @param data implementation-specific data required to cleanly remove the plugin
     */
    function onUninstall(bytes calldata data) external;

    /**
     * @notice Returns the list of interface ids provided by this plugin. 
     */
    function providedInterfaces() external view returns (bytes4[] memory);

    /**
     * @notice Returns the selectors of the functions that this plugin will validate. 
     */
    function validates() external view returns (bytes4[] memory); 

    /**
     * @notice Returns the selectors of the functions that this plugin will execute. 
     */
    function executes() external view returns (bytes4[] memory);

    /**
     * @notice Returns the selectors of the functions that this plugin will post validate. 
     */
    function postExecs() external view returns (bytes4[] memory); 

    /**
     * @notice called by the plugin executor to validate a function
     * @param _msg the original message received by the Plugin Executor
     */
    function beforeHook(
        Message calldata _msg
    ) external payable returns (bytes memory);

    /**
     * @notice called by the plugin executor to execute a function
     * @notice execute functions can only add new functions on the Plugin Executor. They
     *     cannot replace existing functions. If the Plugin Executor has a function with the 
     *     same selector, the plugin version will never be called.
     * @param _msg the original message received by the Plugin Executor
     */
    function execute(
        Message calldata _msg
    ) external payable returns (bytes memory);

    /**
     * @notice called by the plugin executor to post-validate a function
     * @param _msg the original message received by the Plugin Executor
     */
    function afterHook(
        Message calldata _msg
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
pragma solidity ^0.8.24;

import "contracts/utils/introspection/IERC165.sol";
import "contracts/interfaces/ISimplePlugin.sol";
import "contracts/interfaces/PluginErrorsAndEvents.sol";

/**
 * @title Plugin Executor Interface
 * @author Josh Davis
 * @notice For contracts that will use plugins
 */
interface ISimplePluginExecutor is PluginErrorsAndEvents, IERC165 {
    /**
     * @notice Installs a new plugin
     * @param plugin the plugin to be installed
     * @param pluginInstallData plugin-specific data required to install and configure
     *
     * Requirements:
     * - The plugin MUST NOT already be installed
     * - The plugin MUST NOT provide an execute selector already provided by an installed plugin
     * - Implementation MUST call plugin.onInstall()
     */
    function installSimplePlugin(
        address plugin,
        bytes calldata pluginInstallData
    ) external;

    /**
     * @notice Removes a plugin
     * @param plugin the plugin to be removed
     * @param pluginUninstallData  plugin-specific data required to clean uninstall
     *
     * Requirements:
     * - The plugin MUST be installed
     * - Implementation MUST call plugin.onUninstall()
     */
    function uninstallSimplePlugin(
        address plugin,
        bytes calldata pluginUninstallData
    ) external;

    /**
     * @notice Removes a plugin without reverting if onUninstall() fails
     * @param plugin the plugin to be removed
     * @param pluginUninstallData  plugin-specific data required to clean uninstall
     *
     * Requirements:
     * - The plugin MUST be installed
     * - Implementation MUST call plugin.onUninstall()
     */
    function forceUninstallSimplePlugin(
        address plugin,
        bytes calldata pluginUninstallData
    ) external;

    /**
     * @notice remove the ability of a plugin to implement interfaces and respond to selectors
     * @param plugin the plugin to be removed
     * @param interfaces interface id support to be removed
     * @param selectors function support to be removed
     */
    function removePluginSelectorsAndInterfaces(
        address plugin,
        bytes4[] calldata interfaces,
        bytes4[] calldata selectors
    ) external;

    /**
     *
     * @param oldPlugin the plugin to be removed
     * @param pluginUninstallData plugin-specific data required to clean uninstall
     * @param newPlugin the plugin to be installed
     * @param pluginInstallData plugin-specific data required to install and configure
     * @param force if true, will not revert if oldPlugin.onUninstall() reverts
     *
     * Requirements
     * - removing oldPlugin MUST meet all requirements for `uninstallSimplePlugin`
     * - installing newPlugin MUST meet all requirements for `installSimplePlugin`
     */
    function replaceSimplePlugin(
        address oldPlugin,
        bytes calldata pluginUninstallData,
        address newPlugin,
        bytes calldata pluginInstallData,
        bool force
    ) external;

    /// @notice Execute a call from a plugin through the parent contract.
    /// @dev Permissions must be granted to the calling plugin for the call to go through.
    /// @param data The calldata to send to the parent contract.
    /// @return The return data from the call.
    function executeFromPlugin(
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @notice Execute a call from a plugin to a non-plugin address.
    /// @dev If the target is a plugin, the call SHOULD revert. Permissions MUST be granted to the calling 
    /// plugin for the call to go through.
    /// @param target The address to be called.
    /// @param value The value to send with the call.
    /// @param data The calldata to send to the target.
    /// @return The return data from the call.
    function executeFromPluginExternal(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface PluginErrorsAndEvents {
    event SimplePluginInstalled(address indexed plugin);

    event SimplePluginUninstalled(address indexed plugin);

    event ErrorInPluginUninstall(bytes reason);

    // @notice Revert if a function is called by something other than an ISimplePluginExecutor
    error InvalidPluginExecutor(address notExecutor);

    /// @notice Revert if a function called by something other than an installed plugin
    error CallerIsNotPlugin();

    /// @notice Revert if a function is called by an installed plugin
    error IllegalCallByPlugin();

    /// @notice Revert if a call is to an installed plugin
    error IllegalCallToPlugin();

    /// @notice Revert if fallback can't find the function
    error NoSuchMethodError();

    /// @notice Revert when installing a plugin that executes the same selector as an existing one
    error ExecutePluginAlreadySet(bytes4 func, address plugin);

    /// @notice Revert on install if the plugin has already been installed
    error PluginAlreadyInstalled();

    /// @notice Revert on install if there is a problem with a plugin
    error InvalidPlugin(bytes32 reason);

    /// @notice Revert on uninstall 
    error PluginNotInstalled();

    /// @notice Revert if the calldata passed to onInstall/onUninstall is invalid
    error InvalidInitCode(bytes32 reason);

    /// @notice Revert if validation or execution fails due to bad call data
    error InvalidCallData(bytes4 selector);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes constant FALSE = abi.encodePacked(uint256(0));
bytes constant TRUE = abi.encodePacked(uint256(1));

bytes constant BEFORE_HOOK_SELECTOR = "0x55cdfb83";
bytes constant AFTER_HOOK_SELECTOR = "0x495b0f93";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/bridging/IBridgeable.sol";
import "contracts/access/IViciAccess.sol";
import "contracts/interfaces/ISimplePluginExecutor.sol";
import "contracts/token/extensions/IERC677.sol";

interface IModularViciERC20 is
    IERC20Metadata,
    IViciAccess,
    ISimplePluginExecutor,
    IBridgeable,
    IERC677
{
    function isMain() external returns (bool);
    function vault() external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/access/AccessConstants.sol";

struct BridgeArgs {
    address caller;
    address fromAddress;
    address toAddress;
    uint256 remoteChainId;
    uint256 itemId;
    uint256 amount;
}

struct SendParams {
    address fromAddress;
    uint256 dstChainId;
    address toAddress;
    uint256 itemId;
    uint256 amount;
}

/**
 * @title Bridgeable Interface
 * @dev common interface for bridgeable tokens
 */
interface IBridgeable {
    event SentToBridge(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed itemId,
        uint256 amount,
        address caller,
        uint256 dstChainId
    );

    event ReceivedFromBridge(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed itemId,
        uint256 amount,
        address caller,
        uint256 srcChainId
    );

    /**
     * @dev Callback function to notify when tokens have been sent through a bridge.
     * @dev Implementations SHOULD either lock or burn these tokens.
     * @param args.caller the original message sender
     * @param args.fromAddress the owner of the tokens that were sent
     * @param args.toAddress the destination address on the other chain
     * @param args.remoteChainId the chain id for the destination
     * @param args.itemId the token id for ERC721 or ERC1155 tokens. Ignored for ERC20 tokens.
     * @param args.amount the amount of tokens sent for ERC20 and ERC1155 tokens. Ignored for ERC721 tokens.
     */
    function sentToBridge(BridgeArgs calldata args) external payable;

    /**
     * @dev Callback function to notify when tokens have been sent through a bridge.
     * @dev Implementations SHOULD either unlock or mint these tokens and send them to the `toAddress`.
     * @dev IMPORTANT: access to this function MUST be tightly controlled. Otherwise it's an infinite free tokens function.
     * @param args.caller the original message sender
     * @param args.fromAddress the owner of the tokens that were sent
     * @param args.toAddress the destination address on this chain
     * @param args.srcChainId the chain id for the source
     * @param args.itemId the token id for ERC721 or ERC1155 tokens. Ignored for ERC20 tokens.
     * @param args.amount the amount of tokens sent for ERC20 and ERC1155 tokens. Ignored for ERC721 tokens.
     */
    function receivedFromBridge(BridgeArgs calldata args) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes32 constant DEFAULT_ADMIN = 0x00;
bytes32 constant BANNED = "banned";
bytes32 constant MODERATOR = "moderator";
bytes32 constant ANY_ROLE = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
bytes32 constant BRIDGE_CONTRACT = keccak256("BRIDGE_CONTRACT");
bytes32 constant BRIDGE_ROLE_MGR = keccak256("BRIDGE_ROLE_MGR");
bytes32 constant CREATOR_ROLE_NAME = "creator";
bytes32 constant CUSTOMER_SERVICE = "Customer Service";
bytes32 constant MINTER_ROLE_NAME = "minter";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/access/extensions/IAccessControlEnumerable.sol";

/**
 * @title ViciAccess Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Interface for ViciAccess.
 * @dev External contracts SHOULD refer to implementers via this interface.
 */
interface IViciAccess is IAccessControlEnumerable {
    /**
     * @dev emitted when the owner changes.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    function enforceIsNotSanctioned(address account) external view;

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    function enforceIsNotBanned(address account) external view;

    /**
     * @dev reverts if the account is not the owner and doesn't have the required role.
     */
    function enforceOwnerOrRole(bytes32 role, address account) external view;

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) external view returns (bool);

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) external view returns (bool);
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/IAccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "contracts/access/IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title IERC677 interface
 * @notice ERC677 extends ERC20 by adding the transfer and call function.
 */
interface IERC677 is IERC20Metadata {

    /**
     * @notice transfers `value` to `to` and calls `onTokenTransfer()`.
     * @param to the ERC677 Receiver
     * @param value the amount to transfer
     * @param data the abi encoded call data
     * 
     * Requirements:
     * - `to` MUST implement ERC677ReceiverInterface.
     * - `value` MUST be sufficient to cover the receiving contract's fee.
     * - `data` MUST be the types expected by the receiving contract.
     * - caller MUST be a contract that implements the callback function 
     *     required by the receiving contract.
     * - this contract must represent a token that is accepted by the receiving
     *     contract.
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/interfaces/ISimplePluginExecutor.sol";
import "contracts/common/IOwnerOperator.sol";
import "contracts/token/modular/IModularViciERC20.sol";

interface IModularERC20Ops is IOwnerOperator {
    /* ################################################################
     * Queries
     * ##############################################################*/

    function parent() external view returns (IModularViciERC20);

    /**
     * @dev Returns the total maximum possible that can be minted.
     */
    function getMaxSupply() external view returns (uint256);

    /**
     * @dev Returns the amount that has been minted so far.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the amount available to be minted.
     * @dev {total available} = {max supply} - {amount minted so far}
     */
    function availableSupply() external view returns (uint256);

    /**
     * @dev see IERC20
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Updates available quantities
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC20Receiver-onERC20Received}, which is called upon a safe
     *      transfer.
     */
    function mint(address operator, address toAddress, uint256 amount) external;

    /**
     * @dev see IERC20
     */
    function transfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 amount
    ) external;

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     */
    function burn(
        address operator,
        address fromAddress,
        uint256 amount
    ) external;

    /* ################################################################
     * Approvals / Allowances
     * ##############################################################*/

    /**
     * @dev see IERC20
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 amount) external;

    /**
     * @notice recover assets in banned or sanctioned accounts
     *
     * Requirements
     * - `operator` MUST be the contract owner.
     * - `fromAddress` MUST be banned or OFAC sanctioned
     * - `toAddress` MAY be the zero address, in which case the
     *     assets are burned.
     * - `toAddress` MUST NOT be banned or OFAC sanctioned
     */
    function recoverSanctionedAssets(
        address operator,
        address fromAddress,
        address toAddress
    ) external returns (uint256 amount);

    /* ################################################################
     * Utility Coin Functions
     * ##############################################################*/

    /**
     * @notice Transfers tokens from the caller to a recipient and establishes
     * a vesting schedule.
     * If `transferData.toAddress` already has a locked balance, then
     * - if `transferData.amount` is greater than the airdropThreshold AND `release` is later than the current
     *      lockReleaseDate, the lockReleaseDate will be updated.
     * - if `transferData.amount` is less than the airdropThreshold OR `release` is earlier than the current
     *      lockReleaseDate, the lockReleaseDate will be left unchanged.
     * param transferData describes the token transfer
     * @param release the new lock release date, as a Unix timestamp in seconds
     *
     * Requirements:
     * - caller MUST have the AIRDROPPER role
     * - the transaction MUST meet all requirements for a transfer
     * @dev see IERC20Operations.transfer
     */
    function airdropTimelockedTokens(
        address operator,
        address toAddress,
        address fromAddress,
        uint256 amount,
        uint256 release
    ) external;

    /**
     * @notice Unlocks some or all of `account`'s locked tokens.
     * @param account the user
     * @param unlockAmount the amount to unlock
     *
     * Requirements:
     * - caller MUST be the owner or have the UNLOCK_LOCKED_TOKENS role
     * - `unlockAmount` MAY be greater than the locked balance, in which case
     *     all of the account's locked tokens are unlocked.
     */
    function unlockLockedTokens(
        address operator,
        address account,
        uint256 unlockAmount
    ) external;

    /**
     * @notice Resets the lock period for a batch of addresses
     * @notice This function has no effect on accounts without a locked token balance
     * @param release the new lock release date, as a Unix timestamp in seconds
     * @param addresses the list of addresses to be reset
     *
     * Requirements:
     * - caller MUST be the owner or have the UNLOCK_LOCKED_TOKENS role
     * - `release` MAY be zero or in the past, in which case the users' entire locked balances become unlocked
     * - `addresses` MAY contain accounts without a locked balance, in which case the account is unaffected
     */
    function updateTimelocks(
        address operator,
        uint256 release,
        address[] calldata addresses
    ) external;

    /**
     * @notice Returns the amount of locked tokens for `account`.
     * @param account the user address
     */
    function lockedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Returns the Unix timestamp when a user's locked tokens will be
     * released.
     * @param account the user address
     */
    function lockReleaseDate(address account) external view returns (uint256);

    /**
     * @notice Returns the difference between `account`'s total balance and its
     * locked balance.
     * @param account the user address
     */
    function unlockedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice recovers tokens from lost wallets
     */
    function recoverMisplacedTokens(
        address operator,
        address fromAddress,
        address toAddress
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/interfaces/draft-IERC6093.sol";

bytes32 constant AIRDROP_ROLE_NAME = "airdrop";
bytes32 constant LOST_WALLET = keccak256("lost wallet");
bytes32 constant UNLOCK_LOCKED_TOKENS = keccak256("UNLOCK_LOCKED_TOKENS");

interface ViciERC20RolesErrorsEvents is IERC20Errors {
    /**
     * @notice revert when using lost wallet recovery on a wallet that is not lost.
     */
    error InvalidLostWallet(address wallet);

    /**
     * @notice revert when using sanctioned asset recovery on a wallet that is not sanctioned.
     */
    error InvalidSanctionedWallet(address wallet);

    /**
     * @notice  revert when trying to mint beyond max supply
     */
    error SoldOut();

    /**
     * @notice  emit when assets are recovered from a sanctioned wallet
     */
    event SanctionedAssetsRecovered(address from, address to, uint256 value);

    /**
     * @notice  emit when assets are recovered from a lost wallet
     */
    event LostTokensRecovered(address from, address to, uint256 value);

    /**
     * @notice  emit when a timelock is updated
     */
    event LockUpdated(
        address indexed account,
        uint256 previousRelease,
        uint256 newRelease
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}