/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// File: GMXMarketFull001.sol


pragma solidity ^0.8.17;


contract DeployEscrow is ReentrancyGuard {
    address immutable public Owner;
    address public Keeper;
    address public FeeAddress;

    bool public AllowPurchases = true;
    
    mapping(address => address) public Escrows;
    mapping(address => address) public EscrowsToOwners;
    mapping(address => address) public ListingsToOwners;
    
    address[] public EscrowOwnerArray;
    address[] public ListingArray;
    
    event DeployedEscrow(address indexed Escrow, address indexed EscrowOwner);
    
    receive() external payable {}
    
    fallback() external payable {}
    
    // Owner is the team's Gnosis Safe multisig address with 2/3 confirmations needed to transact, Keeper and FeeAddress can be changed by Owner
    constructor () {
        Owner = 0xeA4D1a08300247F6298FdAF2F68977Af7bf93d01;
        Keeper = 0x26DcbdA37FC1D8abF1FF016947a11Ef972dCb306;
        FeeAddress = 0xc7a5e5E3e2aba9aAa5a4bbe33aAc7ee2b2AA7bE4;
    }
    modifier OnlyOwner() {
        require(msg.sender == Owner, "This function can only be run by the contract owner");
        _;
    }

    modifier OnlyEscrows() {
        require(EscrowsToOwners[msg.sender] != address(0), "This function can only be run by escrow accounts");
        _;
    }

    // Deploy Escrow account for user
    function Deploy() external nonReentrant returns (address Address) {
        address payable _EscrowOwner = payable(msg.sender);
        require(Escrows[msg.sender] == address(0), "Can only have 1 Escrow at a time, close other Escrow before creating new one!");
        BFREscrow NewEscrow = new BFREscrow(_EscrowOwner);
        Address = address(NewEscrow);
        require(Address != address(0), "Deploy Escrow failed!");
        emit DeployedEscrow(Address, _EscrowOwner);
        Escrows[_EscrowOwner] = Address;
        EscrowsToOwners[Address] = _EscrowOwner;
        EscrowOwnerArray.push(_EscrowOwner);
    }
    
    // Deploy buyer Escrow account during offer/purchase
    function DeployBuyerEscrow(address payable _BuyerAddress) external OnlyEscrows nonReentrant returns (address EscrowAddress) {
        require(Escrows[_BuyerAddress] == address(0), "Buyer already has an escrow account!");
        BFREscrow NewEscrow = new BFREscrow(_BuyerAddress);
        EscrowAddress = address(NewEscrow);
        require(EscrowAddress != address(0), "Deploy Escrow failed!");
        emit DeployedEscrow(EscrowAddress, _BuyerAddress);
        Escrows[_BuyerAddress] = EscrowAddress;
        EscrowsToOwners[EscrowAddress] = _BuyerAddress;
        EscrowOwnerArray.push(_BuyerAddress);
    }

    // Gets list of Escrow accounts currently for sale
    function GetListings(uint256 _Limit, uint256 _Offset) external view returns (address[] memory) {
        uint256 LimitPlusOffset = _Limit + _Offset;
        require(_Limit <= ListingArray.length, "Please ensure Limit is less than or equal to the ListingArray current length");
        require(_Offset < ListingArray.length, "Please ensure Offset is less than the ListingArray current length");
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
        uint256 Index = IndexOfEscrowOwnerArray(_Address);
        delete Escrows[_Address];
        delete EscrowsToOwners[msg.sender];
        EscrowOwnerArray[Index] = EscrowOwnerArray[EscrowOwnerArray.length - 1];
        EscrowOwnerArray.pop();
    }

    // Cleans up array/mappings related listings when ended
    function DeleteListing(address _Address) external OnlyEscrows nonReentrant {
        uint256 Index = IndexOfListingArray(_Address);
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

    // Delete any expired listings from ListingsArray and ListingsToOwners
    function CleanListings() external nonReentrant {
        require(msg.sender == Keeper, "Only the Keeper can run this function");
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (BFREscrow(payable(ListingArray[i])).EndAt() <= block.timestamp) {
                delete ListingsToOwners[ListingArray[i]];
                ListingArray[i] = ListingArray[ListingArray.length - 1];
                ListingArray.pop();
            }
        }
    }

    // Checks if any listings are expired, if any are expired returns true if not returns false
    function CheckForExpired() external view returns (bool) {
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (BFREscrow(payable(ListingArray[i])).EndAt() <= block.timestamp) {
                return true;
            }
        }
        return false;
    }

    // Sets the keeper address
    function SetKeeper(address _Address) external OnlyOwner nonReentrant {
        Keeper = _Address;
    }

    // Sets the keeper address
    function SetFeeAddress(address _Address) external OnlyOwner nonReentrant {
        FeeAddress = _Address;
    }

    // Sets whether or not sales can be completed in the marketplace (for turning off in case of end of life)
    function SetAllowPurchases(bool _Bool) external OnlyOwner nonReentrant {
        AllowPurchases = _Bool;
    }
    
    // Withdraw all ETH from this contract
    function WithdrawETH() external payable OnlyOwner nonReentrant {
        require(address(this).balance > 0, "No ETH to withdraw");
        (bool sent, ) = Owner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external OnlyOwner nonReentrant {
        IERC20(_tokenaddress).transfer(Owner, _Amount);
    }
    
    // Private function for internal use
    function IndexOfEscrowOwnerArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < EscrowOwnerArray.length; i++) {
            if (EscrowOwnerArray[i] == _Target) {
                return i;
            }
        }
        revert("Not found");
    }

    // Private function for internal use
    function IndexOfListingArray(address _Target) private view returns (uint256) {
        for (uint256 i = 0; i < ListingArray.length; i++) {
            if (ListingArray[i] == _Target) {
                return i;
            }
        }
        revert("Not found");
    }
}

contract BFREscrow is ReentrancyGuard {
    address immutable public Owner;
    
    DeployEscrow immutable MasterContract;
    BFREscrow EscrowContract;
    
    address payable immutable public EscrowOwner;
    
    address constant private BFREligible = 0xb9EF6aeA8d8292978ece20838B75CE60aabc87C0;
    address constant private EsBFR = 0x92914A456EbE5DB6A69905f029d6160CF51d3E6a;
    address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant private BFR = 0x1A5B0aaF478bf1FDA7b934c76E7692D722982a6D;
    address constant private BFRRewardRouter = 0xbD5FBB3b2610d34434E316e1BABb9c3751567B67;
    address constant private stakedBFRTracker = 0x173817F33f1C09bCb0df436c2f327B9504d6e067;
    address constant private bonusBFRTracker = 0x00B88B6254B51C7b238c4675E6b601a696CC1aC8;
    address constant private feeBFRTracker = 0xBABF696008DDAde1e17D302b972376B8A7357698;
    address constant private BFRVester = 0x92f424a2A65efd48ea57b10D345f4B3f2460F8c8;
    address constant private stakedBlpTracker = 0x7d1d610Fe82482412842e8110afF1cB72FA66bc8;
    address constant private feeBlpTracker = 0xCCFd47cCabbF058Fb5566CC31b552b21279bd89a;
    address constant private BlpVester = 0x22499C54cD0F38fE75B2805619Ac8d0e815e3DC7;
    
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPeripheryPayments constant refundrouter = IPeripheryPayments(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address BFRRewardContract = 0xbD5FBB3b2610d34434E316e1BABb9c3751567B67;
    address tokenIn = 0x1A5B0aaF478bf1FDA7b934c76E7692D722982a6D;
    address tokenOut = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    
    uint256 constant private MaxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    uint256 public SalePrice = 0;
    uint256 public EndAt;
    
    bool public SaleIneligible = false;
    bool public IsSold = false;
    bool public IsPurchased = false;
    bool public IsActive = true;
    
    event Listed(address indexed Lister);
    event Purchased(address indexed Purchaser, address indexed Lister);
    
    constructor (address payable _EscrowOwner) {
        Owner = msg.sender;
        MasterContract = DeployEscrow(payable(Owner));
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
    
    // Compound Escrow account and claim rewards for Escrow Owner (choice of receiving as ETH (true) or WETH (false)
    function CompoundAndClaim() external payable nonReentrant ClosedEscrow OnlyEscrowOwner {
        IBFRRewardRouter(BFRRewardRouter).handleRewards(
            false,
            false,
            true,
            true,
            true,
            true
        );
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Transfer BFR account out of Escrow to _Receiver
    function TransferOut(address _Receiver) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        IERC20(BFR).approve(stakedBFRTracker, MaxApproveValue);
        IBFRRewardRouter(BFRRewardRouter).signalTransfer(_Receiver);
        if (MasterContract.ListingsToOwners(address(this)) != address(0)) {
            IBFRDeployEscrow(Owner).DeleteListing(address(this));
        }
        SalePrice = 0;
        SaleIneligible = true;
        EndAt = block.timestamp;
    }
    
    // Transfer BFR account out of Escrow to Escrow Owner
    function TransferOutEscrowOwner() external nonReentrant ClosedEscrow {
        require((MasterContract.EscrowsToOwners(msg.sender)) != address(0));
        IERC20(BFR).approve(stakedBFRTracker, MaxApproveValue);
        IBFRRewardRouter(BFRRewardRouter).signalTransfer(EscrowOwner);
        SalePrice = 0;
        SaleIneligible = true;
        EndAt = block.timestamp;
    }
    
    // Transfer BFR account in to Escrow
    function TransferIn() public nonReentrant ClosedEscrow {
        IBFRRewardRouter(BFRRewardRouter).acceptTransfer(msg.sender);
    }
    
    // Transfer BFR account in to Escrow private function
    function TransferInPrivate() private {
        IBFRRewardRouter(BFRRewardRouter).acceptTransfer(msg.sender);
    }

    // Set Escrow BFR account for sale
    function SetForSale(uint256 _SalePrice, uint8 _Length) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        bool Eligible = IBFREligible(BFREligible).TransferEligible(address(this));
        if (Eligible) {
            IERC20(BFR).approve(stakedBFRTracker, MaxApproveValue);
            TransferInPrivate();
        }
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(SalePrice == 0 || block.timestamp >= EndAt, "Already Listed");
        require(IERC20(feeBFRTracker).balanceOf(address(this)) != 0 || IERC20(stakedBlpTracker).balanceOf(address(this)) != 0, "Escrow Account Can't be empty when listing for sale");
        require(_SalePrice > 0, "Choose a price greater than 0");
        require(_Length <= 30, "Max sale length = 30 days");
        IsPurchased = false;
        SalePrice = _SalePrice;
        EndAt = block.timestamp + _Length * 1 days;
        if (MasterContract.ListingsToOwners(address(this)) == address(0)) {
            MasterContract.SetListingsToOwners(EscrowOwner);
            MasterContract.PushListing();
        }
        emit Listed(address(this));
    }
    
    // Change price for Escrow
    function ChangePrice(uint256 _NewPrice) external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(SalePrice > 0, "Not currently for sale");
        require(block.timestamp < EndAt, "Listing is expired");
        SalePrice = _NewPrice;
    }
    
    // Make BFR account in Escrow no longer for sale (but potentially still accepting offers)
    function EndEarly() external nonReentrant ClosedEscrow OnlyEscrowOwner {
        require(SalePrice > 0, "Not currently for sale");
        require(block.timestamp < EndAt, "Already Expired");
        SalePrice = 0;
        EndAt = block.timestamp;
        IBFRDeployEscrow(Owner).DeleteListing(address(this));
    }
    
    // Allow buyer to make purchase at sellers list price (if Escrow is listed)
    function MakePurchase(bool _StartTransferOut, bool _PayInETH, uint24 _PoolFee) external payable nonReentrant ClosedEscrow {
        address Receiver = (MasterContract.Escrows(msg.sender));
        require(MasterContract.AllowPurchases(), "Purchase transactions are turned off for this contract!");
        require(SaleIneligible == false, "Escrow not eligible for sale");
        require(SalePrice > 0, "Not For Sale");
        require(block.timestamp < EndAt, "Ended/Not Available");
        if (_PayInETH) {
            ETHBFR(SalePrice, _PoolFee);
        }
        require(IERC20(BFR).balanceOf(msg.sender) >= SalePrice, "Insufficient Funds");
        require(IERC20(BFR).allowance(msg.sender, address(this)) >= SalePrice, "Please approve this contract to use your BFR");
        if (Receiver == address(0)) {
            Receiver = IBFRDeployEscrow(Owner).DeployBuyerEscrow(msg.sender);
        }
        uint256 Payout = 39 * SalePrice / 40;
        uint256 Fees = SalePrice - Payout;
        IBFRRewardRouter(BFRRewardRouter).handleRewards(
            false,
            false,
            false,
            false,
            false,
            true
        );
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
        IERC20(BFR).transferFrom(msg.sender, EscrowOwner, Payout);
        IERC20(BFR).transferFrom(msg.sender, MasterContract.FeeAddress(), Fees);
        IBFRRewardRouter(BFRRewardRouter).signalTransfer(Receiver);
        IERC20(BFR).approve(stakedBFRTracker, MaxApproveValue);
        IBFREscrow(Receiver).TransferIn();
        if (_StartTransferOut) {
            bool Eligible = IBFREligible(BFREligible).TransferEligible(msg.sender);
            require(Eligible, "Please purchase using an account that has never staked BFR/esBFR or held Blp");
            IBFREscrow(Receiver).TransferOutEscrowOwner();
        }
        EndAt = block.timestamp;
        SalePrice = 0;
        IBFREscrow(Receiver).SetIsPurchased();
        IsSold = true;
        IBFRDeployEscrow(Owner).DeleteListing(address(this));
        emit Purchased(Receiver, address(this));
    }
    
    // Close Escrow once empty
    function CloseEscrow() external nonReentrant ClosedEscrow OnlyEscrowOwner {
    	require(IERC20(BFR).balanceOf(address(this)) == 0, "Please Remove BFR");
        require(IERC20(WETH).balanceOf(address(this)) == 0, "Please Remove WETH");
        require(IERC20(stakedBlpTracker).balanceOf(address(this)) == 0, "Please Remove Blp");
        require(IERC20(feeBFRTracker).balanceOf(address(this)) == 0, "Please Remove staked BFR and/or bonus points");
        IBFRDeployEscrow(Owner).ResetCloseEscrow(EscrowOwner);
        IsActive = false;
    }
    
    // Withdraw all ETH from this contract
    function WithdrawETH() external payable nonReentrant OnlyEscrowOwner {
        require(address(this).balance > 0, "No ETH to withdraw");
        (bool sent, ) = EscrowOwner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external nonReentrant OnlyEscrowOwner {
        IERC20(_tokenaddress).transfer(EscrowOwner, _Amount);
    }
    
    // Allow purchasing Escrow account to set selling Escrow account "IsPurchased" to true during purchase
    function SetIsPurchased() external nonReentrant ClosedEscrow {
        require(MasterContract.EscrowsToOwners(msg.sender) != address(0));
        IsPurchased = true;
    }

    // Internal function for buying with ETH
    function ETHBFR(uint256 amountOut, uint24 poolFee) private {
        if (poolFee == 5050) {
            uint256 amountOutHalf1 = amountOut / 2;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = msg.value / 2;
            uint256 amountInMaxHalf2 = msg.value - amountInMaxHalf1;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: BFR,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: BFR,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
            refundrouter.refundETH();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
        } else if (poolFee == 7525) {
            uint256 amountOutHalf2 = amountOut / 4;
            uint256 amountOutHalf1 = amountOut - amountOutHalf2;
            uint256 amountInMaxHalf2 = msg.value / 4;
            uint256 amountInMaxHalf1 = msg.value - amountInMaxHalf2;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: BFR,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: BFR,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
            refundrouter.refundETH();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
        } else if (poolFee == 2575) {
            uint256 amountOutHalf1 = amountOut / 4;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = msg.value / 4;
            uint256 amountInMaxHalf2 = msg.value - amountInMaxHalf1;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: BFR,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: BFR,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
            refundrouter.refundETH();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
        }
        else {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: WETH,
                    tokenOut: BFR,
                    fee: poolFee,
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: msg.value,
                    sqrtPriceLimitX96: 0
                });

            router.exactOutputSingle{ value: msg.value }(params);
            refundrouter.refundETH();
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "refund failed");
            }
        
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

interface IBFRRewardRouter {
    function stakeBFR(uint256 _amount) external;
    function stakeEsBFR(uint256 _amount) external;
    function unstakeBFR(uint256 _amount) external;
    function unstakeEsBFR(uint256 _amount) external;
    function claim() external;
    function claimEsBFR() external;
    function claimFees() external;
    function compound() external;
    function handleRewards(
        bool _shouldClaimBFR,
        bool _shouldStakeBFR,
        bool _shouldClaimEsBFR,
        bool _shouldStakeEsBFR,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimUsdc
    ) external;
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

interface IPriceConsumerV3 {
    function getLatestPrice() external view;
}

interface IBFREscrow {
    function TransferOutEscrowOwner() external;
    function TransferIn() external;
    function SetIsPurchased() external;
}

interface IBFRDeployEscrow {
    function DeployBuyerEscrow(address _Address) external returns (address addr);
    function ResetCloseEscrow(address _address) external;
    function DeleteListing(address _address) external;
    function SetListingsToOwners(address _Address) external;
}

interface IBFREligible {
    function TransferEligible(address _receiver) external view returns (bool Eligible);
}

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

interface IPeripheryPayments {
    function refundETH() external payable;
}