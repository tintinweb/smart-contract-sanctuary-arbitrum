// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing external interfaces for interaction with other contracts
import "./Interfaces.sol";

/**
 * @title CF
 * @dev Main contract for the Protocol, handling payments, distributions, and ownership.
 */
contract CF {
    // Immutable token address for ERC20 token, set at contract deployment
    IERC20 immutable token;

    // Immutable token address for the SFT contract, set at contract deployment
    ISFT immutable sft;

    /**
     * @dev Constructor to set initial values for token and SFT contract addresses.
     * @param ierc20 Address of the IERC20 token contract.
     * @param isft Address of the ISFT contract.
     */
    constructor(address ierc20, address isft) {
        token = IERC20(ierc20);
        sft = ISFT(isft);
    }

    // Mapping to store offers, identified by a unique ID
    mapping(uint256 => Offer) public list;

    // Struct to define an offer with percentages and whole price
    struct Offer {
        uint8 percentages;
        uint256 whole_price;
    }

    // Mapping to store investor offers, identified by their address and a unique ID
    mapping(address => mapping(uint256 => Offer)) public list_investors;

    // Mapping to store shareholders information, identified by a unique ID
    mapping(uint256 => Shareholder) public assets;

    // Struct to define shareholder information with owner-sold percentages, addresses, and percentages
    struct Shareholder {
        uint8 Owner_sold;
        address[] addr;
        uint8[] percentage;
    }

    // Events for logging actions within the contract
    event List(uint256 id, uint8 total_percentages, uint256 whole_price);
    event Investor_List(
        address addressOfInvestor,
        uint8 total_percentages,
        uint256 whole_price
    );
    event Delist(uint256 id);
    event Investor_Delist(address addressOfInvestor);
    event Purchase(
        address addressOfInvestor,
        uint256 id,
        uint256 amount,
        uint256 percentage
    );
    event Burn(uint256 id, uint256 slot);

    /**
     * @dev Function to list an offer for a token.
     * @param id The ID of the token.
     * @param percentages The percentage of the token to list.
     * @param whole_price The whole price for the token.
     */
    function listOffer(
        uint256 id,
        uint8 percentages,
        uint256 whole_price
    ) public {
        require(sft.ownerOf(id) == msg.sender, "You are not Owner of the SFT");
        require(list[id].percentages == 0, "You are already listed");
        uint8 total = percentages + assets[id].Owner_sold;
        require(total <= 100, "You want to sell too much");
        list[id] = Offer(percentages, whole_price);
        emit List(id, percentages, whole_price);
    }

    /**
     * @dev Function to delist an offer for a token.
     * @param id The ID of the token.
     */
    function delistOffer(uint256 id) public {
        require(sft.ownerOf(id) == msg.sender, "You are not Owner of the SFT");
        list[id] = Offer(0, 0);
        emit Delist(id);
    }

    /**
     * @dev Function to find an address in the list of shareholders.
     * @param id The ID of the token.
     * @param addr The address to find.
     * @return The index of the address in the list or 100 if not found.
     */
    function findAddress(uint256 id, address addr) public view returns (uint8) {
        uint256 len = assets[id].addr.length;
        uint8 i;
        for (i = 0; i < len; ++i) {
            if (assets[id].addr[i] == addr) return i;
        }
        return 100;
    }

    /**
     * @dev Function to buy a token offer.
     * @param id The ID of the token.
     */
    function buy(uint256 id) public {
        uint256 amount = list[id].whole_price;
        require(amount != 0, "This id not listed");
        require(
            token.balanceOf(msg.sender) >= amount,
            "You don`t have enough money for this operation"
        );
        token.transferFrom(msg.sender, sft.ownerOf(id), amount);
        uint8 perc = list[id].percentages;
        list[id] = Offer(0, 0);
        assets[id].Owner_sold += perc;
        uint8 i = findAddress(id, msg.sender);
        if (i == 100) {
            assets[id].addr.push(msg.sender);
            assets[id].percentage.push(perc);
        } else {
            assets[id].percentage[i] += perc;
        }
        emit Purchase(msg.sender, id, amount, perc);
    }

    /**
     * @dev Function for an investor to list their share of a token.
     * @param id The ID of the token.
     * @param percentages The percentage of the token to list.
     * @param whole_price The whole price for the token.
     */
    function investor_want_to_list(
        uint256 id,
        uint8 percentages,
        uint256 whole_price
    ) public {
        uint8 i = findAddress(id, msg.sender);
        uint8 perc = assets[id].percentage[i];
        require(i != 100, "You don`t have a fraction of this SFT");
        require(
            list_investors[msg.sender][id].percentages == 0,
            "You are already listed"
        );
        require(perc >= percentages, "You don`t have enough percentages");
        list_investors[msg.sender][id] = Offer(percentages, whole_price);
        emit Investor_List(msg.sender, percentages, whole_price);
    }

    /**
     * @dev Function for an investor to delist their share of a token.
     * @param id The ID of the token.
     */
    function investor_delist_Offer(uint256 id) public {
        list_investors[msg.sender][id] = Offer(0, 0);
        emit Investor_Delist(msg.sender);
    }

    /**
     * @dev Function to buy a token share from an investor.
     * @param investor The address of the investor.
     * @param id The ID of the token.
     */
    function buy_from_investor(address investor, uint256 id) public {
        uint256 amount = list_investors[investor][id].whole_price;
        uint8 perc = list_investors[investor][id].percentages;
        require(
            token.balanceOf(msg.sender) > amount,
            "You don`t have enough money"
        );
        token.transferFrom(msg.sender, investor, amount);
        list_investors[investor][id] = Offer(0, 0);
        uint8 i = findAddress(id, investor);
        assets[id].percentage[i] -= perc;
        if (assets[id].percentage[i] == 0) remove_element(id, i);
        if (sft.ownerOf(id) == msg.sender) {
            assets[id].Owner_sold -= perc;
        } else {
            assets[id].addr.push(msg.sender);
            assets[id].percentage.push(perc);
        }
    }

    /**
     * @dev Function to remove an element from the list of shareholders.
     * @param id The ID of the token.
     * @param i The index of the element to remove.
     */
    function remove_element(uint256 id, uint8 i) public {
        uint256 length = assets[id].percentage.length - 1;
        assets[id].percentage[i] = assets[id].percentage[length];
        assets[id].addr[i] = assets[id].addr[length];
        assets[id].addr.pop();
        assets[id].percentage.pop();
    }

    /**
     * @dev Getter function to return the list of addresses of shareholders for a given token ID.
     * @param id The ID of the token.
     * @return The list of addresses of shareholders.
     */
    function addr_array(uint256 id) public view returns (address[] memory) {
        return assets[id].addr;
    }

    /**
     * @dev Getter function to return the list of percentages of shareholders for a given token ID.
     * @param id The ID of the token.
     * @return The list of percentages of shareholders.
     */
    function perc_array(uint256 id) public view returns (uint8[] memory) {
        return assets[id].percentage;
    }

    /**
     * @dev Function to check the owner's sold percentage for a given token ID.
     * @param id The ID of the token.
     * @return The owner's sold percentage.
     */
    function Owner_check(uint256 id) public view returns (uint8) {
        return assets[id].Owner_sold;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface ISFT {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function slotOf(uint256 tokenId_) external view returns (uint256);
    function getTokenId() external view returns (uint256);
    function getPricePerQuery(uint256 id) external view returns (uint256);
    function getModel(uint256 idApp) external view returns (uint256);
    function getData(uint256 idApp) external view returns (uint256);
}

interface ICF {
    function Owner_check(uint256 id) external view returns (uint8);
    function perc_array(uint256 id) external view returns (uint8[] memory);
    function addr_array(uint256 id) external view returns (address[] memory);
}