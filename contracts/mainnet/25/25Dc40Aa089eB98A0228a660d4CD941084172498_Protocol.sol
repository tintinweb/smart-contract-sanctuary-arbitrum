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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Interfaces.sol";

// Main contract for the Protocol, handling payments, distributions, and ownership
contract Protocol {
    // Commission rate applied to transactions, initially set to 10%
    uint256 public commissionRate = 0;

    // Total revenue collected through the protocol
    uint256 public totalRevenue = 0;
    uint256 public totalRevenue2 = 0;
    bool pay = true;
    bool art = false;

    // Address of the contract owner
    address public owner;

    // Addresses for interacting with external contracts and tokens
    ISFT immutable sft; // Funding contract address
    ICF immutable cf;
    IERC20 immutable token1;
    IERC20 immutable token2;
    IERC20 token;

    /**
     * @dev Constructor to set up initial values or states.
     * @param ierc20 Address of the first ERC20 token contract.
     * @param vierc20 Address of the second ERC20 token contract.
     * @param isft Address of the ISFT contract.
     * @param icf Address of the ICF contract.
     */
    constructor(address ierc20, address vierc20, address isft, address icf) {
        owner = msg.sender;
        token1 = IERC20(ierc20);
        token2 = IERC20(vierc20);
        token = IERC20(ierc20);
        sft = ISFT(isft);
        cf = ICF(icf);
    }

    // Modifier to restrict certain operations to the contract owner only
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the Owner");
        _;
    }

    // Events for logging various actions and transactions within the contract
    event Transaction(
        address payer,
        address userWallet,
        uint256 moneyToAppOwner,
        uint256 moneyToModelOwner,
        uint256 moneyToDataOwner,
        uint256 IdAppOwner,
        uint256 IdModelOwner,
        uint256 IdDataOwner
    );

    function payment(uint256 IdAppOwner, address userWallet) public {
        uint256 IdModelOwner = sft.getModel(IdAppOwner);
        uint256 IdDataOwner = sft.getData(IdAppOwner);

        uint256 priceIdData = 0;
        uint256 priceIdApp = sft.getPricePerQuery(IdAppOwner);
        uint256 priceIdModel = sft.getPricePerQuery(IdModelOwner);
        if (pay) priceIdData = sft.getPricePerQuery(IdDataOwner);

        uint256 total = priceIdApp + priceIdModel + priceIdData;
        uint256 commission = (total * commissionRate) / 100;
        totalRevenue += commission;
        uint256 all = total + commission;

        if (art) token2.transferFrom(msg.sender, address(this), all);
        else token1.transferFrom(msg.sender, address(this), all);
        fraction(priceIdApp, IdAppOwner);
        fraction(priceIdModel, IdModelOwner);
        if (pay) fraction(priceIdData, IdDataOwner);

        emit Transaction(
            msg.sender,
            userWallet,
            priceIdApp,
            priceIdModel,
            priceIdData,
            IdAppOwner,
            IdModelOwner,
            IdDataOwner
        );
    }

    function create_art(uint256 IdAppOwner, address userWallet) public {
        art = true;
        token = token2;
        payment2(IdAppOwner, userWallet);
        token = token1;
        art = false;
    }

    function payment2(uint256 IdAppOwner, address userWallet) public {
        pay = false;
        payment(IdAppOwner, userWallet);
        pay = true;
    }

    /**
     * @dev Function to distribute funds among shareholders.
     * @param price Amount to distribute.
     * @param id ID of the token.
     */
    function fraction(uint256 price, uint256 id) public {
        if (cf.Owner_check(id) != 0) {
            address[] memory addr = cf.addr_array(id);
            uint8[] memory perc = cf.perc_array(id);
            for (uint i = 0; i < addr.length; ++i) {
                uint256 part = (price * perc[i]) / 100;
                price -= part;
                token.transfer(addr[i], part);
            }
        }
        if (id != 0) token.transfer(sft.ownerOf(id), price);
    }

    /**
     * @dev Getter function to return the balance of the protocol's pool.
     * @return Balances of the two tokens.
     */
    function getBalancePool() public view returns (uint256, uint256) {
        return (
            token1.balanceOf(address(this)),
            token2.balanceOf(address(this))
        );
    }

    /**
     * @dev Getter function to return the total revenue collected.
     * @return Total revenues for the two tokens.
     */
    function getTotalRevenue() public view returns (uint256, uint256) {
        return (totalRevenue, totalRevenue2);
    }

    /**
     * @dev Function to check if a given ID is the owner of a slot.
     * @param id ID to check.
     * @return Boolean indicating if the ID is the owner.
     */
    function checkOwner(uint256 id) public view returns (bool) {
        if (id != 0 && id <= sft.getTokenId()) return true;
        return false;
    }

    /**
     * @dev Function for the owner to set a new commission rate; rate cannot exceed 100%.
     * @param newRate New commission rate to set.
     */
    function setCommissionRate(uint256 newRate) public onlyOwner {
        require(newRate <= 100, "Commission rate must be <= 100%");
        commissionRate = newRate;
    }

    /**
     * @dev Getter function to return the current commission rate.
     * @return Current commission rate.
     */
    function getRate() public view returns (uint256) {
        return commissionRate;
    }

    /**
     * @dev Function for the owner to withdraw accumulated revenue.
     */
    function withdraw() public onlyOwner {
        token1.transfer(owner, token1.balanceOf(address(this)));
        token2.transfer(owner, token2.balanceOf(address(this)));
    }
}