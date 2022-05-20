// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SRTicketsDiscountsRemote {
    struct DiscountResponse {
        bool hasDiscountCode;
        bool hasDiscountAddress;
        bool hasTokenDiscount;
        uint256 discountAmount;
    }
    address public SRTicketsAddress;

    struct SenderAndTokenDiscountBuyer {
        address sender;
        bool tockenDiscountBuyer;
    }

    function getAttendee(address sender, uint256 index)
        public
        view
        returns (SRTickets.Attendee memory)
    {}

    function getDiscountView(
        SenderAndTokenDiscountBuyer memory stdb,
        bool discountCodeTicketAttendee,
        SRTickets.DiscountCode memory,
        bool discountAddressTicketAttendee,
        SRTickets.DiscountAddress memory,
        bool tokenDiscountTicketAttendee,
        SRTickets.TokenDiscount memory,
        address tokenDiscountAttendee
    ) public view returns (DiscountResponse memory) {}

    function setAttendee(
        uint256 attendeeIndex,
        SRTickets.Attendee memory newAttendee,
        SRTickets.Attendee memory attendee,
        address sender,
        bool resell,
        bool refund
    ) public {}
}

contract SRTickets is ReentrancyGuard {
    using Counters for Counters.Counter;
    address public owner;
    using SafeERC20 for IERC20;
    bool public allowSelfRefund;
    uint256 public refundFee;
    uint256 public resellFee;
    struct Ticket {
        uint256 qty;
        Counters.Counter used;
        uint256 price;
        uint256 endDate;
        uint256 startDate;
    }

    /*  struct DiscountResponse {
        bool hasDiscountCode;
        bool hasDiscountAddress;
        bool hasTokenDiscount;
        uint256 discountAmount;
    }
*/
    struct DiscountCode {
        uint256 qty;
        Counters.Counter used;
        uint256 amount;
        string code;
        uint256 endDate;
        uint256 startDate;
    }

    struct DiscountAddress {
        address buyer;
        uint256 qty;
        Counters.Counter used;
        uint256 amount;
        string code;
        uint256 endDate;
        uint256 startDate;
    }

    struct TokenDiscount {
        address token;
        uint256 minAmount;
        uint256 qty;
        Counters.Counter used;
        uint256 amount;
        uint256 endDate;
        uint256 startDate;
    }

    struct Attendee {
        string email;
        string fname;
        string lname;
        string bio;
        string job;
        string company;
        string social;
        string ticket;
        string discountCode;
        address tokenDiscount;
        address sender;
        address buyToken;
        uint256 pricePaid;
        uint256 pricePaidInToken;
        bool cancelled;
        uint256 refunded;
        bool allowResell;
        uint256 resellPrice;
        string code;
    }

    mapping(string => Ticket) public tickets;
    mapping(string => DiscountCode) public discountCodes;
    mapping(address => DiscountAddress) public discountAddresses;
    mapping(address => TokenDiscount) public tokenDiscounts;
    mapping(address => mapping(string => bool)) public tokenDiscountTickets;
    mapping(address => mapping(address => bool)) public tokenDiscountBuyer;
    mapping(string => mapping(string => bool)) public discountCodeTickets;
    mapping(address => mapping(string => bool)) public discountAddressTickets;

    mapping(address => address) public priceFeeds;

    address public token;
    address private discountContract;
    mapping(address => Counters.Counter) public attendeesCount;

    constructor(address _discountContract) {
        discountContract = _discountContract;
        owner = address(msg.sender);
        allowSelfRefund = true;
        refundFee = 15;
        resellFee = 15;
        //mainnet        priceFeeds[address(0)] = 0x9326BFA02ADD2366b30bacB125260Af641031331;
        //priceFeeds[address(0)] = 0x7f8847242a530E809E17bF2DA5D2f9d2c4A43261; //kovan optimism
        //priceFeeds[address(0)] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5; //mainnet optimism
        priceFeeds[address(0)] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612; //mainnet arbitrum
        setTicket(100, 100, 9949326229, 1, "conference-only");
        setTicket(25, 50, 9949326229, 1, "iftar-meetup");
        /* //btc
        priceFeeds[
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        ] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
        //usdt
        priceFeeds[
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        ] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        //dai
        priceFeeds[
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        ] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
        //bnb
        priceFeeds[
            0xB8c77482e45F1F44dE1745F52C74426C631bDD52
        ] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
        //usdc
        priceFeeds[
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        ] = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
        //link
        priceFeeds[
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        ] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
        //aave
        priceFeeds[
            0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
        ] = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
        //tusd
        priceFeeds[
            0x0000000000085d4780B73119b644AE5ecd22b376
        ] = 0xec746eCF986E2927Abd291a2A1716c940100f8Ba;
        //mim
        priceFeeds[
            0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3
        ] = 0x7A364e8770418566e3eb2001A96116E6138Eb32F;
        //rai
        priceFeeds[
            0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919
        ] = 0x483d36F6a1d063d580c7a24F9A42B346f3a69fbb;
        //fei
        priceFeeds[
            0x956F47F50A910163D8BF957Cf5846D573E7f87CA
        ] = 0x31e0a88fecB6eC0a411DBe0e9E76391498296EE9;
        //uni
        priceFeeds[
            0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
        ] = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;
        //sushi
        priceFeeds[
            0x6B3595068778DD592e39A122f4f5a5cF09C90fE2
        ] = 0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7;
        //xsushi
        priceFeeds[
            0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272
        ] = 0xCC1f5d9e6956447630d703C8e93b2345c2DE3D13;
        //mkr
        priceFeeds[
            0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
        ] = 0xec1D1B3b0443256cc3860e24a46F108e699484Aa;
        //yfi
        priceFeeds[
            0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e
        ] = 0xA027702dbb89fbd58938e4324ac03B58d812b0E1;
        //comp
        priceFeeds[
            0xc00e94Cb662C3520282E6f5717214004A7f26888
        ] = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;
        //matic
        priceFeeds[
            0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0
        ] = 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676;
        //1inch
        priceFeeds[
            0x111111111117dC0aa78b770fA6A738034120C302
        ] = 0xc929ad75B72593967DE83E7F7Cda0493458261D9;
        //busd
        priceFeeds[
            0x4Fabb145d64652a948d72533023f6E7A623C7C53
        ] = 0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A;
    */
    }

    modifier validNameSlug(string memory _slug) {
        bytes memory tmpSlug = bytes(_slug); // Uses memory
        require(tmpSlug.length > 0, "Not valid slug");
        _;
    }
    modifier onlyOwner() {
        require(address(msg.sender) == owner, "!owner");
        _;
    }

    function setPriceFeed(address address1, address address2) public onlyOwner {
        priceFeeds[address1] = address2;
    }

    function setToken(address newToken) public onlyOwner {
        token = newToken;
    }

    function setRefund(
        bool allow,
        uint256 rffee,
        uint256 rsfee
    ) public onlyOwner {
        allowSelfRefund = allow;
        refundFee = rffee;
        resellFee = rsfee;
    }

    function setTicket(
        uint256 qty,
        uint256 price,
        uint256 endDate,
        uint256 startDate,
        string memory slug
    ) public validNameSlug(slug) onlyOwner {
        Ticket memory t;
        t.qty = qty;
        t.price = price;
        t.endDate = endDate;
        t.startDate = startDate;
        tickets[slug] = t;
    }

    function setTokenDiscount(
        address discountToken,
        uint256 minAmount,
        uint256 qty,
        uint256 amount,
        uint256 endDate,
        uint256 startDate,
        string[] memory ticketsToAdd,
        string[] memory ticketsToRemove
    ) public onlyOwner {
        TokenDiscount memory td;
        td.token = discountToken;
        td.minAmount = minAmount;
        td.qty = qty;
        td.amount = amount;
        td.endDate = endDate;
        td.startDate = startDate;
        tokenDiscounts[discountToken] = td;

        for (uint256 i = 0; i < ticketsToAdd.length; i++) {
            tokenDiscountTickets[discountToken][ticketsToAdd[i]] = true;
        }
        for (uint256 i = 0; i < ticketsToRemove.length; i++) {
            tokenDiscountTickets[discountToken][ticketsToRemove[i]] = false;
        }
    }

    function setDiscountCodes(
        string memory code,
        uint256 qty,
        uint256 amount,
        uint256 endDate,
        uint256 startDate,
        string[] memory ticketsToAdd,
        string[] memory ticketsToRemove
    ) public onlyOwner {
        DiscountCode memory td;
        td.qty = qty;
        td.amount = amount;
        td.endDate = endDate;
        td.startDate = startDate;
        discountCodes[code] = td;

        for (uint256 i = 0; i < ticketsToAdd.length; i++) {
            discountCodeTickets[code][ticketsToAdd[i]] = true;
        }
        for (uint256 i = 0; i < ticketsToRemove.length; i++) {
            discountCodeTickets[code][ticketsToRemove[i]] = false;
        }
    }

    function setDiscountAddresses(
        address buyer,
        uint256 qty,
        uint256 amount,
        uint256 endDate,
        uint256 startDate,
        string[] memory ticketsToAdd,
        string[] memory ticketsToRemove
    ) public onlyOwner {
        DiscountAddress memory td;
        td.qty = qty;
        td.amount = amount;
        td.endDate = endDate;
        td.startDate = startDate;
        discountAddresses[buyer] = td;

        for (uint256 i = 0; i < ticketsToAdd.length; i++) {
            discountAddressTickets[buyer][ticketsToAdd[i]] = true;
        }

        for (uint256 i = 0; i < ticketsToRemove.length; i++) {
            discountAddressTickets[buyer][ticketsToRemove[i]] = false;
        }
    }

    function mintTicket(Attendee[] memory buyAttendees, address buyToken)
        public
        payable
    {
        uint256 total = 0;
        uint256 discount = 0;
        //AggregatorV3Interface priceFeed;
        uint256 valueToken = 0;
        require(priceFeeds[buyToken] != address(0), "token not supported");
        int256 usdPrice = 326393000000;

        for (uint256 i = 0; i < buyAttendees.length; i++) {
            require(
                tickets[buyAttendees[i].ticket].used.current() <
                    tickets[buyAttendees[i].ticket].qty,
                "sold out"
            );
            require(
                tickets[buyAttendees[i].ticket].startDate < block.timestamp,
                "not available yet"
            );
            require(
                tickets[buyAttendees[i].ticket].endDate > block.timestamp,
                "not available anymore"
            );
            discount = getDiscount(msg.sender, buyAttendees[i]);

            uint256 priceToPay = getPrice(discount, buyAttendees[i].ticket);
            total += priceToPay;
            buyAttendees[i].sender = msg.sender;
            buyAttendees[i].pricePaid = tickets[buyAttendees[i].ticket].price; //priceToPay;
            buyAttendees[i].pricePaidInToken = getPriceFromUSD(priceToPay);

            buyAttendees[i].buyToken = buyToken;
            setAttendee(
                attendeesCount[msg.sender].current(),
                buyAttendees[i],
                buyAttendees[i],
                msg.sender,
                false,
                false
            );
            tickets[buyAttendees[i].ticket].used.increment();
            attendeesCount[msg.sender].increment();
        }
        //AggregatorV3Interface priceFeed;
        //priceFeed = AggregatorV3Interface(priceFeeds[buyToken]);
        //(, int256 price, , , ) = priceFeed.latestRoundData();
        require(total > 0, "total 0");
        if (buyToken == address(0)) {
            require(msg.value >= getPriceFromUSD(total), "price too low");
        } else {
            valueToken = getPriceFromUSD(total);
            require(
                IERC20(buyToken).transferFrom(
                    address(msg.sender),
                    address(this),
                    uint256(valueToken)
                ),
                "transfer failed"
            );
        }
        //emit LMint(msg.sender, mints, "minted");
    }

    function getPriceFromUSD(uint256 priceUSD) private view returns (uint256) {
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(priceFeeds[address(0)]);
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        //int256 latestPrice = 326393000000;
        uint256 price = uint256(
            (int256(priceUSD * 10**8) * 10**18) / latestPrice
        );
        return price;
    }

    function getPrice(uint256 discount, string memory ticket)
        public
        view
        returns (uint256)
    {
        uint256 price = tickets[ticket].price;
        return price - (price * discount) / 100;
    }

    function getAttendee(address sender, uint256 index)
        private
        view
        returns (Attendee memory attendee)
    {
        SRTicketsDiscountsRemote dc = SRTicketsDiscountsRemote(
            discountContract
        );
        attendee = dc.getAttendee(sender, index);
    }

    function setAttendee(
        uint256 attendeeIndex,
        Attendee memory newAttendee,
        Attendee memory attendee,
        address sender,
        bool resell,
        bool isRefund
    ) private {
        SRTicketsDiscountsRemote dc = SRTicketsDiscountsRemote(
            discountContract
        );
        dc.setAttendee(
            attendeeIndex,
            newAttendee,
            attendee,
            sender,
            resell,
            isRefund
        );
    }

    function getDiscountView(address sender, Attendee memory attendee)
        public
        view
        returns (uint256)
    {
        SRTicketsDiscountsRemote.DiscountResponse memory dr = getDiscountAmount(
            sender,
            attendee
        );
        return dr.discountAmount; //discountCodeTickets["50pc-discount"]["conference-only"];
    }

    function getDiscount(address sender, Attendee memory attendee)
        private
        returns (uint256)
    {
        SRTicketsDiscountsRemote.DiscountResponse memory dr = getDiscountAmount(
            sender,
            attendee
        );
        if (dr.hasDiscountCode) {
            discountCodes[attendee.discountCode].used.increment();
        }
        if (dr.hasDiscountAddress) {
            discountAddresses[sender].used.increment();
        }
        if (dr.hasTokenDiscount) {
            tokenDiscounts[attendee.tokenDiscount].used.increment();
            tokenDiscountBuyer[attendee.tokenDiscount][sender] = true;
        }
        return dr.discountAmount;
    }

    function getDiscountAmount(address sender, Attendee memory attendee)
        private
        view
        returns (SRTicketsDiscountsRemote.DiscountResponse memory)
    {
        //check sender Discount code
        SRTicketsDiscountsRemote dc = SRTicketsDiscountsRemote(
            discountContract
        );
        SRTicketsDiscountsRemote.SenderAndTokenDiscountBuyer memory stdb;
        stdb.sender = sender;
        stdb.tockenDiscountBuyer = tokenDiscountBuyer[attendee.tokenDiscount][
            sender
        ];
        SRTicketsDiscountsRemote.DiscountResponse memory dr = dc
            .getDiscountView(
                stdb,
                discountCodeTickets[attendee.discountCode][attendee.ticket],
                discountCodes[attendee.discountCode],
                discountAddressTickets[attendee.sender][attendee.ticket],
                discountAddresses[attendee.sender],
                tokenDiscountTickets[attendee.tokenDiscount][attendee.ticket],
                tokenDiscounts[attendee.tokenDiscount],
                attendee.tokenDiscount
            );
        return dr;
    }

    /*   function getThing(address sender, Attendee memory attendee)
        public
        view
        returns (address)
    {
        //        return discountAddressTickets[attendee.sender][attendee.ticket];
        //return discountAddresses[0x70997970C51812dc3A010C7d01b50e0d17dc79C8];
        SRTicketsDiscountsRemote dc = SRTicketsDiscountsRemote(
            discountContract
        );
        return dc.SRTicketsAddress();
    }*/

    function updateAttendee(uint256 attendeeIndex, Attendee memory newAttendee)
        public
        payable
    {
        Attendee memory oldAttendee = getAttendee(msg.sender, attendeeIndex);

        require(
            oldAttendee.sender == msg.sender || msg.sender == owner,
            "not allowed"
        );
        if (
            oldAttendee.sender == msg.sender &&
            keccak256(abi.encodePacked(newAttendee.ticket)) !=
            keccak256(abi.encodePacked(oldAttendee.ticket))
        ) {
            if (tickets[newAttendee.ticket].price > oldAttendee.pricePaid) {
                require(
                    msg.value >
                        getPriceFromUSD(
                            tickets[newAttendee.ticket].price -
                                oldAttendee.pricePaid
                        ),
                    "new ticket more expensive"
                );
                tickets[newAttendee.ticket].used.increment();
                tickets[newAttendee.ticket].used.decrement();
                oldAttendee.pricePaid = tickets[newAttendee.ticket].price;
            }
        }
        setAttendee(
            attendeeIndex,
            newAttendee,
            oldAttendee,
            msg.sender,
            false,
            false
        );
    }

    function refund(
        address buyer,
        uint256 attendeeIndex,
        uint256 amount,
        bool cancel
    ) public onlyOwner {
        Attendee memory attendee = getAttendee(buyer, attendeeIndex);
        require(
            attendee.pricePaidInToken >= amount,
            "refund higher than paid price"
        );

        if (attendee.buyToken != address(0)) {
            IERC20(attendee.buyToken).safeTransfer(
                address(attendee.sender),
                amount
            );
            attendee.refunded = amount;
            attendee.cancelled = cancel;
            setAttendee(
                attendeeIndex,
                attendee,
                attendee,
                attendee.sender,
                false,
                true
            );
        } else {
            (bool ok, ) = address(buyer).call{value: amount}("");
            require(ok, "Failed");
            attendee.refunded = amount;
            attendee.cancelled = true;
            setAttendee(
                attendeeIndex,
                attendee,
                attendee,
                attendee.sender,
                false,
                true
            );
        }
    }

    function selfRefund(uint256 attendeeIndex) public nonReentrant {
        Attendee memory attendee = getAttendee(msg.sender, attendeeIndex);
        require(attendee.sender == msg.sender, "sender is not buyer");
        require(allowSelfRefund, "refund not possible");
        require(!attendee.cancelled, "already cancelled");
        require(
            tickets[attendee.ticket].endDate > block.timestamp,
            "refund not possible anymore"
        );
        uint256 amount = attendee.pricePaidInToken -
            (refundFee * attendee.pricePaidInToken) /
            100;
        if (attendee.buyToken != address(0)) {
            IERC20(attendee.buyToken).safeTransfer(
                address(attendee.sender),
                amount
            );
            attendee.refunded = amount;
            attendee.cancelled = true;
            setAttendee(
                attendeeIndex,
                attendee,
                attendee,
                attendee.sender,
                false,
                true
            );
        } else {
            (bool ok, ) = address(attendee.sender).call{value: amount}("");
            require(ok, "Failed");
            attendee.refunded = amount;
            attendee.cancelled = true;
            setAttendee(
                attendeeIndex,
                attendee,
                attendee,
                attendee.sender,
                false,
                true
            );
        }
    }

    function buyResellable(uint256 attendeeIndex, Attendee memory newAttendee)
        public
        payable
        nonReentrant
    {
        Attendee memory attendee = getAttendee(
            newAttendee.sender,
            attendeeIndex
        );
        bool canUpdate = false;
        require(attendee.allowResell, "not for sell");
        if (attendee.buyToken != address(0)) {
            require(
                IERC20(attendee.buyToken).transferFrom(
                    address(msg.sender),
                    address(this),
                    uint256((attendee.resellPrice * resellFee) / 100)
                ),
                "transfer failed"
            );
            require(
                IERC20(attendee.buyToken).transferFrom(
                    address(msg.sender),
                    address(attendee.sender),
                    uint256(
                        attendee.resellPrice -
                            (attendee.resellPrice * resellFee) /
                            100
                    )
                ),
                "transfer failed"
            );
            canUpdate = true;
        } else {
            require(msg.value == attendee.resellPrice, "not enough fund");
            (bool ok, ) = attendee.sender.call{
                value: attendee.resellPrice -
                    (attendee.resellPrice * resellFee) /
                    100
            }("");
            require(ok, "Failed");
            canUpdate = true;
        }
        if (canUpdate) {
            setAttendee(
                attendeeIndex,
                newAttendee,
                attendee,
                msg.sender,
                true,
                false
            );
        }
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token != address(0)) {
            IERC20(_token).safeTransfer(address(owner), _amount);
        } else {
            uint256 amount = address(this).balance;
            (bool ok, ) = owner.call{value: amount}("");
            require(ok, "Failed");
        }
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /*   function getAttendee(address sender, uint256 index)
        external
        view
        returns (Attendee memory)
    {
        //SRTicketsRemote str = SRTicketsRemote(sender);
        //Attendee memory x = str.attendees(sender, index);
        return attendees[sender][index];
    }
    */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.14;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ISRTickets {
    mapping(address => Counters.Counter) public attendeesCount;
}

contract SRTicketsDiscounts {
    using Counters for Counters.Counter;
    struct DiscountResponse {
        bool hasDiscountCode;
        bool hasDiscountAddress;
        bool hasTokenDiscount;
        uint256 discountAmount;
    }
    struct SenderAndTokenDiscountBuyer {
        address sender;
        bool tockenDiscountBuyer;
    }
    mapping(address => mapping(uint256 => Attendee)) private attendees;

    mapping(address => Counters.Counter) public attendeesCount;
    struct Attendee {
        string email;
        string fname;
        string lname;
        string bio;
        string job;
        string company;
        string social;
        string ticket;
        string discountCode;
        address tokenDiscount;
        address sender;
        address buyToken;
        uint256 pricePaid;
        uint256 pricePaidInToken;
        bool cancelled;
        uint256 refunded;
        bool allowResell;
        uint256 resellPrice;
        string code;
    }

    struct DiscountCode {
        uint256 qty;
        Counters.Counter used;
        uint256 amount;
        string code;
        uint256 endDate;
        uint256 startDate;
    }

    struct DiscountAddress {
        address buyer;
        uint256 qty;
        Counters.Counter used;
        uint256 amount;
        string code;
        uint256 endDate;
        uint256 startDate;
    }

    struct TokenDiscount {
        address token;
        uint256 minAmount;
        uint256 qty;
        Counters.Counter used;
        uint256 amount;
        uint256 endDate;
        uint256 startDate;
    }
    address public SRTicketsAddress;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setSRTicketsAddress(address newAddr) public {
        require(msg.sender == owner, "not owner");
        SRTicketsAddress = newAddr;
    }

    function setAttendee(
        uint256 attendeeIndex,
        Attendee memory newAttendee,
        Attendee memory attendee,
        address sender,
        bool resell,
        bool refund
    ) public {
        require(msg.sender == SRTicketsAddress, "not allowed");
        Attendee memory exAttendee = attendee;
        attendee.email = newAttendee.email;
        attendee.fname = newAttendee.fname;
        attendee.lname = newAttendee.lname;
        attendee.social = newAttendee.social;
        attendee.bio = newAttendee.bio;
        attendee.job = newAttendee.job;
        attendee.company = newAttendee.company;
        attendee.allowResell = newAttendee.allowResell;
        attendee.resellPrice = newAttendee.resellPrice;
        attendee.ticket = newAttendee.ticket;
        if (refund) {
            attendee.refunded = newAttendee.refunded;
            attendee.cancelled = newAttendee.cancelled;
        }
        if (resell) {
            attendees[sender][attendeeIndex].sender = sender;
            attendees[sender][attendeeIndex].cancelled = false;
            attendees[exAttendee.sender][attendeeIndex].cancelled = true;
            attendees[exAttendee.sender][attendeeIndex].allowResell = false;
            attendee.allowResell = false;
            attendee.resellPrice = 0;
        }
        attendees[sender][attendeeIndex] = attendee;
    }

    function getDiscountCodeAmount(
        bool discountCodeTicketAttendee,
        uint256 dcQty,
        uint256 dcStartDate,
        uint256 dcEndDate,
        uint256 dcUsed,
        uint256 dcAmount
    ) public view returns (uint256, bool found) {
        uint256 discountAmount = 0;

        if (discountCodeTicketAttendee) {
            if (
                dcUsed < dcQty &&
                dcStartDate < block.timestamp &&
                dcEndDate > block.timestamp
            ) {
                discountAmount = dcAmount;
                found = true;
            }
        }
        return (discountAmount, found);
    }

    function getDiscountAddressAmount(
        bool discountAddressTicketAttendee,
        uint256 daQty,
        uint256 daStartDate,
        uint256 daEndDate,
        uint256 daUsed,
        uint256 daAmount,
        uint256 discountAmount
    ) public view returns (uint256, bool found) {
        if (discountAddressTicketAttendee) {
            if (
                daQty > daUsed &&
                daStartDate < block.timestamp &&
                daEndDate > block.timestamp &&
                daAmount > discountAmount &&
                daAmount > 0
            ) {
                return (daAmount, true);
            }
        }
        return (discountAmount, found);
    }

    function getTokenDiscountAmount(
        SenderAndTokenDiscountBuyer memory stdb,
        uint256 discountAmount,
        bool tokenDiscountTicketAttendee,
        TokenDiscount memory ts,
        address tokenDiscountAttendee
    ) public view returns (uint256, bool found) {
        if (
            tokenDiscountAttendee != address(0) && tokenDiscountTicketAttendee
        ) {
            //check sender balance
            IERC20 tokenDiscount = IERC20(tokenDiscountAttendee);
            uint256 balance = tokenDiscount.balanceOf(stdb.sender);

            if (
                (balance > ts.minAmount &&
                    ts.used._value < ts.qty &&
                    ts.startDate < block.timestamp &&
                    ts.endDate > block.timestamp &&
                    ts.amount > discountAmount &&
                    !stdb.tockenDiscountBuyer)
            ) {
                return (ts.amount, true);
            }
        }

        return (discountAmount, found);
    }

    function getDiscountView(
        SenderAndTokenDiscountBuyer memory stdb,
        bool discountCodeTicketAttendee,
        DiscountCode memory dc,
        bool discountAddressTicketAttendee,
        DiscountAddress memory da,
        bool tokenDiscountTicketAttendee,
        TokenDiscount memory ts,
        address tokenDiscountAttendee
    ) public view returns (DiscountResponse memory) {
        //check sender Discount code
        uint256 discountAmount = 0;
        DiscountResponse memory dr;
        (discountAmount, dr.hasDiscountCode) = getDiscountCodeAmount(
            discountCodeTicketAttendee,
            dc.qty,
            dc.startDate,
            dc.endDate,
            dc.used._value,
            dc.amount
        );
        (discountAmount, dr.hasDiscountAddress) = getDiscountAddressAmount(
            discountAddressTicketAttendee,
            da.qty,
            da.startDate,
            da.endDate,
            da.used._value,
            da.amount,
            discountAmount
        );
        if (dr.hasDiscountAddress) {
            dr.hasDiscountCode = false;
        }
        (discountAmount, dr.hasTokenDiscount) = getTokenDiscountAmount(
            stdb,
            discountAmount,
            tokenDiscountTicketAttendee,
            ts,
            tokenDiscountAttendee
        );
        if (dr.hasTokenDiscount) {
            dr.hasDiscountAddress = false;
            dr.hasDiscountCode = false;
        }
        dr.discountAmount = discountAmount;
        return dr;
    }

    function getAttendee(address sender, uint256 index)
        public
        view
        returns (Attendee memory)
    {
        //SRTicketsRemote str = SRTicketsRemote(sender);
        //Attendee memory x = str.attendees(sender, index);
        return attendees[sender][index];
    }

    function getAttendeeSpent(address sender) public view returns (uint256) {
        ISRTickets sr = ISRTickets(SRTicketsAddress);
        uint256 count = sr.attendeesCount(sender);
        uint256 totalPaidInToken = 0;
        for (uint256 i = 0; i < count; i++) {
            totalPaidInToken += attendees[sender][i].pricePaidInToken;
        }

        return totalPaidInToken;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TT") {
        mintTokens();
    }

    function mintTokens() public {
        _mint(msg.sender, 100000000000000000000000);
    }

    function mintTokensTo(address beneficiary) public {
        _mint(beneficiary, 100000000000000000000000);
    }
}