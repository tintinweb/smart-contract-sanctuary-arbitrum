/**
 *Submitted for verification at Arbiscan on 2023-08-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: SNTLMarket2.1.sol


pragma solidity ^0.8.19;


contract DeployEscrow is ReentrancyGuard {
    address immutable public Owner;
    address public FeeAddress;
    address[] public EscrowOwnerArray;
    address[] public ListingArray;
    
    bool public AllowPurchases = true;
    
    mapping(address => address) public Escrows;
    mapping(address => address) public EscrowsToOwners;
    mapping(address => address) public ListingsToOwners;
    mapping(address => uint256) public EscrowCounter;
    
    uint256 public FeeAmount = 25;
    uint256 public MaxOffers = 9;
    uint256 public MinGMX = 10000000000000000;
    uint256 public MinGLP = 1000000000000000000;

    event DeployedEscrow(address indexed Escrow, address indexed EscrowOwner);
    event Listed(address indexed Lister, address indexed ListingAddress, uint256 ListPrice);
    event Purchased(address indexed Purchaser, address indexed Lister, address indexed Listing, uint256 PurchasePrice, bool OfferAccepted);
    event PriceChange(address indexed Lister, address indexed ListingAddress, uint256 OldPrice, uint256 NewPrice);
    event OfferMade(address indexed Offerer, address indexed Listing, uint256 ListPrice, uint256 OfferPrice);
    
    receive() external payable {}
    
    fallback() external payable {}
    
    // Owner is the team's Gnosis Safe multisig address with 2/3 confirmations needed to transact, FeeAddress can be changed by Owner
    constructor () {
        Owner = 0xeA4D1a08300247F6298FdAF2F68977Af7bf93d01;
        FeeAddress = 0xc7a5e5E3e2aba9aAa5a4bbe33aAc7ee2b2AA7bE4;
    }

    modifier OnlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    modifier OnlyEscrows() {
        require(EscrowsToOwners[msg.sender] != address(0));
        _;
    }

    // Allows the team to set the max number of offers outstanding a listing can have at once
    function SetMaxOffers(uint256 _MaxOffers) public nonReentrant OnlyOwner {
        MaxOffers = _MaxOffers;
    }

    // Allows the team to set the minimum number of GMX/esGMX and GLP required to list an account
    function SetMinGMXGLP(uint256 _MinGMX, uint256 _MinGLP) public nonReentrant OnlyOwner {
        MinGMX = _MinGMX;
        MinGLP = _MinGLP;
    }

    // Allows the team to set the fee to 2.5% or lower
    function SetFeeAmount(uint256 _FeeAmount) public nonReentrant OnlyOwner {
        require(_FeeAmount <= 25);
        FeeAmount = _FeeAmount;
    }

    // Allow escrow contract to emit event when listing
    function EmitListed(address _Lister, address _ListingAddress, uint256 _ListPrice) external nonReentrant OnlyEscrows {
        emit Listed(_Lister, _ListingAddress, _ListPrice);
    }

    // Allow escrow contract to emit event when purchased
    function EmitPurchased(address _Purchaser, address _Lister, address _ListingAddress, uint256 _PurchasePrice, bool _OfferAccepted) external nonReentrant OnlyEscrows {
        emit Purchased(_Purchaser, _Lister, _ListingAddress, _PurchasePrice, _OfferAccepted);
    }

    // Allow escrow contract to emit event when price changed
    function EmitPriceChange(address _Lister, address _ListingAddress, uint256 _OldPrice, uint256 _NewPrice) external nonReentrant OnlyEscrows {
        emit PriceChange(_Lister, _ListingAddress, _OldPrice, _NewPrice);
    }

    // Allow escrow contract to emit event when offer is made
    function EmitOfferMade(address _Offerer, address _ListingAddress, uint256 _SalePrice, uint256 _OfferPrice) external nonReentrant OnlyEscrows {
        emit OfferMade(_Offerer, _ListingAddress, _SalePrice, _OfferPrice);
    }

    // Deploy Escrow account, complete account transfer into escrow and list account for user
    function List(bytes32 _Salt, uint256 _SalePrice) external nonReentrant returns (address Address) {
        address payable _EscrowOwner = payable(msg.sender);
        GMXEscrow EscrowContract = (new GMXEscrow{salt: _Salt}(_EscrowOwner));
        Address = address(EscrowContract);
        emit DeployedEscrow(Address, _EscrowOwner);
        Escrows[_EscrowOwner] = Address;
        EscrowsToOwners[Address] = _EscrowOwner;
        EscrowOwnerArray.push(_EscrowOwner);
        EscrowContract.SetForSale(_SalePrice);
        ListingsToOwners[Address] = _EscrowOwner;
        ListingArray.push(Address);
        emit Listed(_EscrowOwner, Address, _SalePrice);
    }
    
    // Deploy buyer Escrow account during offer/purchase
    function DeployBuyerEscrow(address payable _BuyerAddress) external OnlyEscrows nonReentrant returns (address EscrowAddress) {
        require(Escrows[_BuyerAddress] == address(0), "Buyer already has an escrow account!");
        GMXEscrow NewEscrow = new GMXEscrow(_BuyerAddress);
        EscrowAddress = address(NewEscrow);
        require(EscrowAddress != address(0));
        emit DeployedEscrow(EscrowAddress, _BuyerAddress);
        Escrows[_BuyerAddress] = EscrowAddress;
        EscrowsToOwners[EscrowAddress] = _BuyerAddress;
        EscrowOwnerArray.push(_BuyerAddress);
    }

    // Gets list of Escrow accounts currently for sale
    function GetListings(uint256 _Limit, uint256 _Offset) external view returns (address[] memory) {
        uint256 LimitPlusOffset = _Limit + _Offset;
        require(_Limit <= ListingArray.length);
        require(_Offset < ListingArray.length);
        uint256 n = 0;
        address[] memory Listings = new address[](_Limit);
        if (LimitPlusOffset > ListingArray.length) {
            LimitPlusOffset = ListingArray.length;
        }
        for (uint256 i = _Offset; i < LimitPlusOffset; i++) {
            address ListingAddress = ListingArray[i];
            Listings[n] = ListingAddress;
            n++;
        }
        return Listings;
    }

    // Gets the number of listings in the ListingsArray
    function GetNumberOfListings() external view returns (uint256) {
        return ListingArray.length;
    }

    // Cleans up array/mappings related to buyer and seller Escrow accounts when closed
    function ResetCloseEscrow(address _Address) external OnlyEscrows nonReentrant {
        EscrowCounter[_Address] += 1;
        uint256 Index = _IndexOfEscrowOwnerArray(_Address);
        delete Escrows[_Address];
        delete EscrowsToOwners[msg.sender];
        EscrowOwnerArray[Index] = EscrowOwnerArray[EscrowOwnerArray.length - 1];
        EscrowOwnerArray.pop();
    }

    // Cleans up array/mappings related listings when ended
    function DeleteListing(address _Address) external OnlyEscrows nonReentrant {
        uint256 Index = _IndexOfListingArray(_Address);
        delete ListingsToOwners[msg.sender];
        ListingArray[Index] = ListingArray[ListingArray.length - 1];
        ListingArray.pop();
    }

    // Sets ListingsToOwners mapping
    function SetListingsToOwners(address _Address) external OnlyEscrows nonReentrant {
        ListingsToOwners[msg.sender] = _Address;
    }

    // Push new Listing in ListingArray
    function PushListing() external OnlyEscrows nonReentrant {
        ListingArray.push(msg.sender);
    }

    // Sets the keeper address
    function SetFeeAddress(address _Address) external OnlyOwner nonReentrant {
        FeeAddress = _Address;
    }

    // Sets whether or not sales can be completed in the marketplace (for turning off in case of end of life)
    function SetAllowPurchases(bool _Bool) external OnlyOwner nonReentrant {
        AllowPurchases = _Bool;
    }
    
    // Allow front end to compute future escrow address
    function ComputeFutureEscrowAddress(bytes32 _Salt) public view returns (address Address) {
        Address = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            _Salt,
            keccak256(abi.encodePacked(
                type(GMXEscrow).creationCode,
                abi.encode(msg.sender)
            ))
        )))));
    }
    
    // Withdraw all ETH from this contract
    function WithdrawETH() external payable OnlyOwner nonReentrant {
        require(address(this).balance > 0);
        (bool sent, ) = Owner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external OnlyOwner nonReentrant {
        IERC20(_tokenaddress).transfer(Owner, _Amount);
    }
    
    // Private function for internal use
    function _IndexOfEscrowOwnerArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < EscrowOwnerArray.length; i++) {
            if (EscrowOwnerArray[i] == _Target) {
                return i;
            }
        }
        revert("Not found");
    }

    // Private function for internal use
    function _IndexOfListingArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (ListingArray[i] == _Target) {
                return i;
            }
        }
        revert("Not found");
    }
}

contract GMXEscrow is ReentrancyGuard {
    address immutable public Owner;
    address payable immutable public EscrowOwner;
    address constant private GMXEligible = 0x0Da48adDA1F4374F110EfD49A02d6665c6B69805;
    address constant private EsGMX = 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;
    address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address constant private USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant private GMXRewardRouter = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    address constant private stakedGmxTracker = 0x908C4D94D34924765f1eDc22A1DD098397c59dD4;
    address constant private bonusGmxTracker = 0x4d268a7d4C16ceB5a606c173Bd974984343fea13;
    address constant private feeGmxTracker = 0xd2D1162512F927a7e282Ef43a362659E4F2a728F;
    address constant private gmxVester = 0x199070DDfd1CFb69173aa2F7e20906F26B363004;
    address constant private stakedGlpTracker = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address constant private feeGlpTracker = 0x4e971a87900b931fF39d1Aad67697F49835400b6;
    address constant private glpVester = 0xA75287d2f8b217273E7FCD7E86eF07D33972042E;
    address constant private GMXRewardContract = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    
    uint256 constant private MaxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 public SalePrice = 0;
    
    bool public SaleIneligible = false;
    bool public IsSold = false;
    bool public IsPurchased = false;
    bool public IsActive = true;
    
    mapping(address => Offer) public offers;
    
    address[] public OfferArray;
    
    struct Offer {
    address buyer;
    uint256 amount;
    }

    DeployEscrow immutable FactoryContract;
    GMXEscrow EscrowContract;
    IPayinETHorUSDC constant PayinETHorUSDC = IPayinETHorUSDC(0xF5DcD1dA67661f869cA71D50927ad77049973b75);
    
    constructor (address payable _EscrowOwner) {
        Owner = msg.sender;
        FactoryContract = DeployEscrow(payable(Owner));
        EscrowOwner = payable(_EscrowOwner);
    }  
    
    modifier OnlyEscrowOwner() {
        require(msg.sender == EscrowOwner);
        _;
    }
    
    modifier OnlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    modifier ClosedEscrow() {
        require(IsActive, "This Escrow account is closed, only WithdrawETH() and WithdrawToken() still function");
        _;
    }
    
    receive() external payable {}
    
    fallback() external payable {}
    
    // Anyone can make an offer if they have '_Amount' GMX and have given the escrow contract approval to transfer that amount of GMX
    function MakeOffer(uint256 _Amount) external nonReentrant ClosedEscrow {
        require(OfferArray.length <= FactoryContract.MaxOffers(), "The maximum number of offers have been made");
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(_Amount > 0);
        require(IERC20(GMX).balanceOf(msg.sender) >= _Amount, "Insufficient GMX for offer");
        require(IERC20(GMX).allowance(msg.sender, address(this)) >= _Amount, "Please approve this contract to use your GMX");
        if (offers[msg.sender].amount == 0) {
            OfferArray.push(msg.sender);
        }
        offers[msg.sender] = Offer({
            buyer: msg.sender,
            amount: _Amount
        });
        FactoryContract.EmitOfferMade(msg.sender, address(this), SalePrice, _Amount);
    }
    
    // Allow seller to accept a pending offer
    function AcceptOffer(address _Buyer, uint256 _Amount) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(FactoryContract.AllowPurchases(), "Purchase transactions are turned off for this contract!");
        require(offers[_Buyer].amount != 0, "No active offer from this buyer");
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(IERC20(GMX).balanceOf(_Buyer) >= _Amount, "Insufficient Funds");
        require(IERC20(GMX).allowance(_Buyer, address(this)) >= _Amount, "Please approve this contract to use your GMX");
        uint256 offerAmount = offers[_Buyer].amount;
        require(_Amount == offerAmount, "Offer has changed!");
        address Receiver = FactoryContract.Escrows(_Buyer);
        if (Receiver == address(0)) {
            Receiver = FactoryContract.DeployBuyerEscrow(payable(_Buyer));
        }
        uint256 Payout = (1000 - FactoryContract.FeeAmount()) * _Amount / 1000;
        uint256 Fees = _Amount - Payout;
        uint256 InitialBalance = address(this).balance;
        IGMXRewardRouter(GMXRewardRouter).handleRewards(
            false,
            false,
            false,
            false,
            false,
            true,
            true
        );
        uint256 UpdatedBalance = address(this).balance;
        uint256 RewardBalance = UpdatedBalance - InitialBalance;
        (bool sent, ) = EscrowOwner.call{value: RewardBalance}("");
        require(sent);
        IERC20(GMX).transferFrom(_Buyer, EscrowOwner, Payout);
        IERC20(GMX).transferFrom(_Buyer, FactoryContract.FeeAddress(), Fees);
        IGMXRewardRouter(GMXRewardRouter).signalTransfer(Receiver);
        IERC20(GMX).approve(stakedGmxTracker, MaxApproveValue);
        IGMXEscrow(Receiver).TransferIn();
        SalePrice = 0;
        IGMXEscrow(Receiver).SetIsPurchased();
        IsSold = true;
        SaleIneligible = true;
        FactoryContract.DeleteListing(payable(address(this)));
        if (OfferArray.length > 0) {
            _ClearOffers();
        }
        FactoryContract.EmitPurchased(_Buyer, EscrowOwner, address(this), _Amount, true);
    }

    // Compound Escrow account and claim rewards for Escrow Owner (choice of receiving as ETH (true) or WETH (false)
    function CompoundAndClaim() external payable nonReentrant ClosedEscrow OnlyEscrowOwner {
        uint256 InitialBalance = address(this).balance;
        IGMXRewardRouter(GMXRewardRouter).handleRewards(
            false,
            false,
            true,
            true,
            true,
            true,
            true
        );
        uint256 UpdatedBalance = address(this).balance;
        uint256 RewardBalance = UpdatedBalance - InitialBalance;
        (bool sent, ) = EscrowOwner.call{value: RewardBalance}("");
        require(sent);
    }

    // Transfer GMX account in to Escrow
    function TransferIn() public nonReentrant ClosedEscrow {
        IGMXRewardRouter(GMXRewardRouter).acceptTransfer(msg.sender);
    }
    
    // Transfer GMX account out of Escrow to _Receiver
    function TransferOut(address _Receiver) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        IERC20(GMX).approve(stakedGmxTracker, MaxApproveValue);
        IGMXRewardRouter(GMXRewardRouter).signalTransfer(_Receiver);
        if (FactoryContract.ListingsToOwners(address(this)) != address(0)) {
            FactoryContract.DeleteListing(payable(address(this)));
        }
        SalePrice = 0;
        SaleIneligible = true;
        if (OfferArray.length > 0) {
            _ClearOffers();
        }
    }
    
    // Transfer GMX account out of Escrow to Escrow Owner
    function TransferOutEscrowOwner() external nonReentrant ClosedEscrow {
        require((FactoryContract.EscrowsToOwners(msg.sender)) != address(0));
        IERC20(GMX).approve(stakedGmxTracker, MaxApproveValue);
        IGMXRewardRouter(GMXRewardRouter).signalTransfer(EscrowOwner);
        SalePrice = 0;
        SaleIneligible = true;
        if (OfferArray.length > 0) {
            _ClearOffers();
        }
    }

    // Set Escrow GMX account for sale
    function SetForSale(uint256 _SalePrice) external nonReentrant ClosedEscrow {
        bool Eligible = IGMXEligible(GMXEligible).TransferEligible(address(this));
        uint256 MinGMX = FactoryContract.MinGMX();
        uint256 MinGLP = FactoryContract.MinGLP();
        if (Eligible) {
            IERC20(GMX).approve(stakedGmxTracker, MaxApproveValue);
            IGMXRewardRouter(GMXRewardRouter).acceptTransfer(EscrowOwner);
        }
        require(msg.sender == EscrowOwner || msg.sender == Owner);
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(IERC20(feeGmxTracker).balanceOf(address(this)) >= MinGMX || IERC20(stakedGlpTracker).balanceOf(address(this)) >= MinGLP || IERC20(EsGMX).balanceOf(address(this)) >= MinGMX, "Escrow Account must have more than the minimum required amounts");
        require(_SalePrice > 0);
        IsPurchased = false;
        SalePrice = _SalePrice;
        if (msg.sender == EscrowOwner) {
            FactoryContract.SetListingsToOwners(EscrowOwner);
            FactoryContract.PushListing();
            FactoryContract.EmitListed(EscrowOwner, address(this), _SalePrice);
        }
    }
    
    // Change price for Escrow
    function ChangePrice(uint256 _NewPrice) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(SalePrice > 0);
        uint256 OldSalePrice = SalePrice;
        SalePrice = _NewPrice;
        FactoryContract.EmitPriceChange(EscrowOwner, address(this), OldSalePrice, SalePrice);
    }
    
    // Make GMX account in Escrow no longer for sale (but potentially still accepting offers)
    function EndEarly() external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(SalePrice > 0);
        SalePrice = 0;
        FactoryContract.DeleteListing(payable(address(this)));
    }
    
    // Allow buyer to make purchase at sellers list price (if Escrow is listed)
    function MakePurchase(bool _StartTransferOut, int8 _BuyToken, uint24 _PoolFee, uint256 _AmountInMax) external payable nonReentrant ClosedEscrow {
        require(FactoryContract.AllowPurchases(), "Purchase transactions are turned off for this contract!");
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(SalePrice > 0);
        address Receiver = (FactoryContract.Escrows(msg.sender));
        uint256 Payout = (1000 - FactoryContract.FeeAmount()) * SalePrice / 1000;
        uint256 Fees = SalePrice - Payout;
        if (Receiver == address(0)) {
            Receiver = FactoryContract.DeployBuyerEscrow(payable(msg.sender));
        }
        if (_BuyToken == 1) {
            PayinETHorUSDC.ETHGMX{ value: msg.value }(SalePrice, _PoolFee, msg.sender);
            IERC20(GMX).transfer(EscrowOwner, Payout);
            IERC20(GMX).transfer(FactoryContract.FeeAddress(), Fees);
        }
        else if (_BuyToken == 2) {
            IERC20(USDC).transferFrom(msg.sender, address(PayinETHorUSDC), _AmountInMax);
            PayinETHorUSDC.USDCGMX(SalePrice, _AmountInMax, _PoolFee, msg.sender);
            IERC20(GMX).transfer(EscrowOwner, Payout);
            IERC20(GMX).transfer(FactoryContract.FeeAddress(), Fees);
        }
        else {
            IERC20(GMX).transferFrom(msg.sender, EscrowOwner, Payout);
            IERC20(GMX).transferFrom(msg.sender, FactoryContract.FeeAddress(), Fees);
        }
        uint256 InitialBalance = address(this).balance;
        IGMXRewardRouter(GMXRewardRouter).handleRewards(
            false,
            false,
            false,
            false,
            false,
            true,
            true
        );
        uint256 UpdatedBalance = address(this).balance;
        uint256 RewardBalance = UpdatedBalance - InitialBalance;
        (bool sent, ) = EscrowOwner.call{value: RewardBalance}("");
        require(sent);
        IGMXRewardRouter(GMXRewardRouter).signalTransfer(Receiver);
        IERC20(GMX).approve(stakedGmxTracker, MaxApproveValue);
        IGMXEscrow(Receiver).TransferIn();
        if (_StartTransferOut) {
            bool Eligible = IGMXEligible(GMXEligible).TransferEligible(msg.sender);
            require(Eligible, "Please purchase using an account that has never staked GMX/esGMX or held GLP");
            IGMXEscrow(Receiver).TransferOutEscrowOwner();
        }
        SalePrice = 0;
        IGMXEscrow(Receiver).SetIsPurchased();
        IsSold = true;
        SaleIneligible = true;
        FactoryContract.DeleteListing(payable(address(this)));
        if (OfferArray.length > 0) {
            _ClearOffers();
        }
        FactoryContract.EmitPurchased(msg.sender, EscrowOwner, address(this), SalePrice, false);
    }
    
    // Close Escrow once empty
    function CloseEscrow() external nonReentrant ClosedEscrow OnlyEscrowOwner {
    	require(IERC20(GMX).balanceOf(address(this)) == 0, "Please Remove GMX");
        require(IERC20(EsGMX).balanceOf(address(this)) == 0, "Please Remove Unstaked esGMX");
        require(IERC20(WETH).balanceOf(address(this)) == 0, "Please Remove WETH");
        require(IERC20(stakedGlpTracker).balanceOf(address(this)) == 0, "Please Remove GLP");
        require(IERC20(feeGmxTracker).balanceOf(address(this)) == 0, "Please Remove staked GMX and/or bonus points");
        FactoryContract.ResetCloseEscrow(payable(EscrowOwner));
        IsActive = false;
    }

    //Allow EscrowOwner to decline all offers
    function CancelAllOffers() external nonReentrant ClosedEscrow OnlyEscrowOwner {
        _ClearOffers();
    }

    //Allow EscrowOwner or Offerer to decline an offer
    function CancelOffer(address _Offerer) external nonReentrant ClosedEscrow {
        require(msg.sender == EscrowOwner || msg.sender == _Offerer);
        _ClearOffer(_Offerer);
    }
    
    // Withdraw all ETH from this contract
    function WithdrawETH() external payable nonReentrant OnlyEscrowOwner {
        require(address(this).balance > 0);
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external nonReentrant OnlyEscrowOwner {
        IERC20(_tokenaddress).transfer(EscrowOwner, _Amount);
    }
    
    // Allow purchasing Escrow account to set selling Escrow account "IsPurchased" to true during purchase
    function SetIsPurchased() external nonReentrant ClosedEscrow {
        require(FactoryContract.EscrowsToOwners(msg.sender) != address(0));
        IsPurchased = true;
    }

    // Gets list of offers for this listing
    function GetOffers(uint256 _Limit, uint256 _Offset) external view returns (address[] memory) {
        uint256 LimitPlusOffset = _Limit + _Offset;
        require(_Limit <= OfferArray.length);
        require(_Offset < OfferArray.length);
        uint256 n = 0;
        address[] memory Offers = new address[](_Limit);
        if (LimitPlusOffset > OfferArray.length) {
            LimitPlusOffset = OfferArray.length;
        }
        for (uint256 i = _Offset; i < LimitPlusOffset; i++) {
            address OfferAddress = OfferArray[i];
            Offers[n] = OfferAddress;
            n++;
        }
        return Offers;
    }

    // Private function for internal use
    function _IndexOfOfferArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < OfferArray.length; i++) {
            if (OfferArray[i] == _Target) {
                return i;
            }
        }
        revert("Offer Not Found");
    }
    
    // Private function for internal use
    function _ClearOffers() private {
        for (uint256 i = 0; i < OfferArray.length; i++) {
            delete offers[OfferArray[i]];
        }
        delete OfferArray;
    }

    // Private function for internal use
    function _ClearOffer(address _Address) private {
        require(offers[_Address].amount > 0);
        uint256 Index = _IndexOfOfferArray(_Address);
        delete offers[_Address];
        if (OfferArray.length == 1) {
            delete OfferArray;
        }
        else {
            OfferArray[Index] = OfferArray[OfferArray.length - 1];
            OfferArray.pop();
        }
    }

    // Gets the number of offers in the OfferArray
    function GetNumberOfOffers() external view returns (uint256) {
        return OfferArray.length;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IGMXRewardRouter {
    function stakeGmx(uint256 _Amount) external;
    function stakeEsGmx(uint256 _Amount) external;
    function unstakeGmx(uint256 _Amount) external;
    function unstakeEsGmx(uint256 _Amount) external;
    function claim() external;
    function claimEsGmx() external;
    function claimFees() external;
    function compound() external;
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

interface IGMXEscrow {
    function TransferOutEscrowOwner() external;
    function TransferIn() external;
    function SetIsPurchased() external;
}

interface IGMXEligible {
    function TransferEligible(address _receiver) external view returns (bool Eligible);
}

interface IPayinETHorUSDC {
    function ETHGMX(uint256 amountOut, uint24 poolFee, address _Buyer) external payable;
    function USDCGMX(uint256 amountOut, uint256 amountInMax, uint24 poolFee, address _Buyer) external;
}