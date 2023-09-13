// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./AconomyFee.sol";
import "./Libraries/LibCalculations.sol";
import "./Libraries/LibNFTLendingBorrowing.sol";

contract NFTlendingBorrowing is
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;

    //STORAGE START ---------------------------------------------------------------------------

    uint256 public NFTid;
    address AconomyFeeAddress;

    /**
     * @notice Deatils for a listed NFT.
     * @param NFTtokenId The Id of the token.
     * @param tokenIdOwner The owner of the nft.
     * @param contractAddress The contract address.
     * @param duration The expected duration.
     * @param expectedAmount The expected amount.
     * @param percent The expected interest percent in bps.
     * @param listed Boolean indicating if the nft is listed.
     * @param bidAccepted Boolean indicating if a bid has been accepted.
     * @param repaid Boolean indicating if amount has been repaid.
     */
    struct NFTdetail {
        uint256 NFTtokenId;
        address tokenIdOwner;
        address contractAddress;
        uint32 duration;
        uint256 expiration;
        uint256 expectedAmount;
        uint16 percent;
        bool listed;
        bool bidAccepted;
        bool repaid;
    }

    /**
     * @notice Deatils for a bid.
     * @param bidId The Id of the bid.
     * @param percent The interest percentage.
     * @param duration The duration of the bid.
     * @param expiration The duration within which bid has to be accepted.
     * @param bidderAddress The address of the bidder.
     * @param ERC20Address The address of the erc20 funds.
     * @param Amount The amount of funds.
     * @param acceptedTimestamp The unix timestamp at which bid has been accepted.
     * @param protocolFee The protocol fee when creating a bid.
     * @param withdrawn Boolean indicating if a bid has been withdrawn.
     * @param bidAccepted Boolean indicating if the bid has been accepted.
     */
    struct BidDetail {
        uint256 bidId;
        uint16 percent;
        uint32 duration;
        uint256 expiration;
        address bidderAddress;
        address ERC20Address;
        uint256 Amount;
        uint256 acceptedTimestamp;
        uint16 protocolFee;
        bool withdrawn;
        bool bidAccepted;
    }

    // NFTid => NFTdetail
    mapping(uint256 => NFTdetail) public NFTdetails;

    // NFTid => Bid[]
    mapping(uint256 => BidDetail[]) public Bids;

    //STORAGE END ----------------------------------------------------------------------------

    // Events
    event AppliedBid(uint256 BidId, uint256 NFTid);
    event PercentSet(uint256 NFTid, uint16 Percent);
    event DurationSet(uint256 NFTid, uint32 Duration);
    event ExpectedAmountSet(uint256 NFTid, uint256 expectedAmount);
    event NFTlisted(uint256 NFTid, uint256 TokenId, address ContractAddress);
    event repaid(uint256 NFTid, uint256 BidId, uint256 Amount);
    event Withdrawn(uint256 NFTid, uint256 BidId, uint256 Amount);
    event NFTRemoved(uint256 NFTId);
    event BidRejected(
        uint256 NFTid,
        uint256 BidId,
        address recieverAddress,
        uint256 Amount
    );
    event AcceptedBid(
        uint256 NFTid,
        uint256 BidId,
        uint256 Amount,
        uint256 ProtocolAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _aconomyFee) public initializer {
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        AconomyFeeAddress = _aconomyFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyOwnerOfToken(address _contractAddress, uint256 _tokenId) {
        require(
            msg.sender == ERC721(_contractAddress).ownerOf(_tokenId),
            "Only token owner can execute"
        );
        _;
    }

    modifier NFTOwner(uint256 _NFTid) {
        require(NFTdetails[_NFTid].tokenIdOwner == msg.sender, "Not the owner");
        _;
    }

    /**
     * @notice Lists the nft for borrowing.
     * @param _tokenId The Id of the token.
     * @param _contractAddress The address of the token contract.
     * @param _percent The interest percentage expected.
     * @param _duration The duration of the loan.
     * @param _expiration The expiration duration of the loan for the NFT.
     * @param _expectedAmount The loan amount expected.
     */
    function listNFTforBorrowing(
        uint256 _tokenId,
        address _contractAddress,
        uint16 _percent,
        uint32 _duration,
        uint256 _expiration,
        uint256 _expectedAmount
    )
        external
        onlyOwnerOfToken(_contractAddress, _tokenId)
        whenNotPaused
        nonReentrant
        returns (uint256 _NFTid)
    {
        require(_contractAddress != address(0));
        require(_percent >= 10);
        require(_expectedAmount >= 10000000);

        _NFTid = ++NFTid;

        NFTdetail memory details = NFTdetail(
            _tokenId,
            msg.sender,
            _contractAddress,
            _duration,
            _expiration + block.timestamp,
            _expectedAmount,
            _percent,
            true,
            false,
            false
        );

        NFTdetails[_NFTid] = details;

        emit NFTlisted(_NFTid, _tokenId, _contractAddress);
    }

    /**
     * @notice Sets the expected percentage.
     * @param _NFTid The Id of the NFTDetail
     * @param _percent The interest percentage expected.
     */
    function setPercent(
        uint256 _NFTid,
        uint16 _percent
    ) public whenNotPaused NFTOwner(_NFTid) {
        require(_percent >= 10, "interest percent should be greater than 0.1%");
        if (_percent != NFTdetails[_NFTid].percent) {
            NFTdetails[_NFTid].percent = _percent;

            emit PercentSet(_NFTid, _percent);
        }
    }

    /**
     * @notice Sets the expected duration.
     * @param _NFTid The Id of the NFTDetail
     * @param _duration The duration expected.
     */
    function setDurationTime(
        uint256 _NFTid,
        uint32 _duration
    ) public whenNotPaused NFTOwner(_NFTid) {
        if (_duration != NFTdetails[_NFTid].duration) {
            NFTdetails[_NFTid].duration = _duration;

            emit DurationSet(_NFTid, _duration);
        }
    }

    /**
     * @notice Sets the expected loan amount.
     * @param _NFTid The Id of the NFTDetail
     * @param _expectedAmount The expected amount.
     */
    function setExpectedAmount(
        uint256 _NFTid,
        uint256 _expectedAmount
    ) public whenNotPaused NFTOwner(_NFTid) {
        require(_expectedAmount >= 10000000);
        if (_expectedAmount != NFTdetails[_NFTid].expectedAmount) {
            NFTdetails[_NFTid].expectedAmount = _expectedAmount;

            emit ExpectedAmountSet(_NFTid, _expectedAmount);
        }
    }

    /**
     * @notice Allows a user to bid a loan for an nft.
     * @param _NFTid The Id of the NFTDetail.
     * @param _bidAmount The amount being bidded.
     * @param _ERC20Address The address of the tokens being bidded.
     * @param _percent The interest percentage for the loan bid.
     * @param _duration The duration of the loan bid.
     * @param _expiration The timestamp after which the bid can be withdrawn.
     */
    function Bid(
        uint256 _NFTid,
        uint256 _bidAmount,
        address _ERC20Address,
        uint16 _percent,
        uint32 _duration,
        uint256 _expiration
    ) external whenNotPaused nonReentrant {
        require(_ERC20Address != address(0));
        require(_bidAmount >= 10000000, "bid amount too low");
        require(_percent >= 10, "interest percent too low");
        require(!NFTdetails[_NFTid].bidAccepted, "Bid Already Accepted");
        require(NFTdetails[_NFTid].listed, "You can't Bid on this NFT");
        require(NFTdetails[_NFTid].expiration > block.timestamp, "Bid time over");

        uint16 fee = AconomyFee(AconomyFeeAddress).AconomyNFTLendBorrowFee();

        BidDetail memory bidDetail = BidDetail(
            Bids[_NFTid].length,
            _percent,
            _duration,
            _expiration + block.timestamp,
            msg.sender,
            _ERC20Address,
            _bidAmount,
            0,
            fee,
            false,
            false
        );

        Bids[_NFTid].push(bidDetail);

        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                address(this),
                _bidAmount
            ),
            "Unable to tansfer Your ERC20"
        );
        emit AppliedBid(Bids[_NFTid].length - 1, _NFTid);
    }

    /**
     * @notice Accepts the specified bid.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function AcceptBid(
        uint256 _NFTid,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        address AconomyOwner = AconomyFee(AconomyFeeAddress)
            .getAconomyOwnerAddress();

        //Calculating Aconomy Fee
        uint256 amountToAconomy = LibCalculations.percent(
            Bids[_NFTid][_bidId].Amount,
            Bids[_NFTid][_bidId].protocolFee
        );

        LibNFTLendingBorrowing.acceptBid(
            NFTdetails[_NFTid],
            Bids[_NFTid][_bidId],
            amountToAconomy,
            AconomyOwner
        );

        emit AcceptedBid(
            _NFTid,
            _bidId,
            Bids[_NFTid][_bidId].Amount - amountToAconomy,
            amountToAconomy
        );
    }

    /**
     * @notice Rejects the specified bid.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function rejectBid(
        uint256 _NFTid,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        LibNFTLendingBorrowing.RejectBid(
            NFTdetails[_NFTid],
            Bids[_NFTid][_bidId]
        );

        emit BidRejected(
            _NFTid,
            _bidId,
            Bids[_NFTid][_bidId].bidderAddress,
            Bids[_NFTid][_bidId].Amount
        );
    }

    function viewRepayAmount(
        uint256 _NFTid,
        uint256 _bidId
    ) external view returns (uint256) {
        if(!Bids[_NFTid][_bidId].bidAccepted) {
            return 0;
        }
        if(NFTdetails[_NFTid].repaid) {
            return 0;
        }
        uint256 percentageAmount = LibCalculations.calculateInterest(
            Bids[_NFTid][_bidId].Amount,
            Bids[_NFTid][_bidId].percent,
            (block.timestamp - Bids[_NFTid][_bidId].acceptedTimestamp) +
                10 minutes
        );
        return Bids[_NFTid][_bidId].Amount + percentageAmount;
    }

    /**
     * @notice Repays the loan amount.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function Repay(
        uint256 _NFTid,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        require(NFTdetails[_NFTid].bidAccepted, "Bid Not Accepted yet");
        require(NFTdetails[_NFTid].listed, "It's not listed for Borrowing");
        require(Bids[_NFTid][_bidId].bidAccepted, "Bid not Accepted");
        require(!NFTdetails[_NFTid].repaid, "Already Repaid");

        // Calculate percentage Amount
        uint256 percentageAmount = LibCalculations.calculateInterest(
            Bids[_NFTid][_bidId].Amount,
            Bids[_NFTid][_bidId].percent,
            block.timestamp - Bids[_NFTid][_bidId].acceptedTimestamp
        );

        NFTdetails[_NFTid].repaid = true;
        NFTdetails[_NFTid].listed = false;

        // transfering Amount to Bidder
        require(
            IERC20(Bids[_NFTid][_bidId].ERC20Address).transferFrom(
                msg.sender,
                Bids[_NFTid][_bidId].bidderAddress,
                Bids[_NFTid][_bidId].Amount + percentageAmount
            ),
            "unable to transfer to bidder Address"
        );

        // transferring NFT to this address
        ERC721(NFTdetails[_NFTid].contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            NFTdetails[_NFTid].NFTtokenId
        );
        emit repaid(
            _NFTid,
            _bidId,
            Bids[_NFTid][_bidId].Amount + percentageAmount
        );
    }

    /**
     * @notice Withdraws the bid amount after expiration.
     * @param _NFTid The Id of the NFTDetail
     * @param _bidId The Id of the bid.
     */
    function withdraw(
        uint256 _NFTid,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        require(
            Bids[_NFTid][_bidId].bidderAddress == msg.sender,
            "You can't withdraw this Bid"
        );
        require(!Bids[_NFTid][_bidId].withdrawn, "Already withdrawn");
        require(
            !Bids[_NFTid][_bidId].bidAccepted,
            "Your Bid has been Accepted"
        );
        if(!NFTdetails[_NFTid].bidAccepted) {
            require(
                block.timestamp > Bids[_NFTid][_bidId].expiration,
                "Can't withdraw Bid before expiration"
            );
        }

        Bids[_NFTid][_bidId].withdrawn = true;

        require(
            IERC20(Bids[_NFTid][_bidId].ERC20Address).transfer(
                msg.sender,
                Bids[_NFTid][_bidId].Amount
            ),
            "unable to transfer to Bidder Address"
        );
        emit Withdrawn(_NFTid, _bidId, Bids[_NFTid][_bidId].Amount);
    }

    /**
     * @notice Removes the nft from listing.
     * @param _NFTid The Id of the NFTDetail
     */
    function removeNFTfromList(uint256 _NFTid) external whenNotPaused {
        require(
            msg.sender ==
                ERC721(NFTdetails[_NFTid].contractAddress).ownerOf(
                    NFTdetails[_NFTid].NFTtokenId
                ),
            "Only token owner can execute"
        );
        require(
            NFTdetails[_NFTid].bidAccepted == false,
            "bid has been accepted"
        );
        if (!NFTdetails[_NFTid].listed) {
            revert("It's aiready removed");
        }

        NFTdetails[_NFTid].listed = false;

        emit NFTRemoved(_NFTid);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract poolStorage is Initializable {
    using EnumerableSet for EnumerableSet.UintSet;

    //STORAGE START -------------------------------------------------------------------------------------------

    // Current number of loans.
    uint256 public loanId;

    // Mapping of loanId to loan information.
    mapping(uint256 => Loan) public loans;

    //poolId => loanId => LoanState
    mapping(uint256 => uint256) public poolLoans;

    enum LoanState {
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID
    }

    /**
     * @notice Deatils for payment.
     * @param principal The principal amount involved.
     * @param interest The interest amount involved.
     */
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    /**
     * @notice Deatils for a loan.
     * @param lendingToken The lending token involved.
     * @param principal The principal amount being borrowed.
     * @param totalRepaid The total funds repaid.
     * @param timestamp The timestamp the loan was created.
     * @param acceptedTimestamp The timestamp the loan was accepted.
     * @param lastRepaidTimestamp The timestamp of the last repayment.
     * @param loanDuration The duration of the loan.
     * @param protocolFee The fee when creating a loan.
     */
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
        uint16 protocolFee;
    }

    /**
     * @notice The payment terms.
     * @param paymentCycleAmount The amount to be paid every cycle.
     * @param monthlyCycleInterest The interest to be paid every cycle.
     * @param paymentCycle The duration of a payment cycle.
     * @param APR The interest rate involved in bps.
     * @param installments The total installments for the loan repayment.
     * @param installmentsPaid The installments paid.
     */
    struct Terms {
        uint256 paymentCycleAmount;
        uint256 monthlyCycleInterest;
        uint32 paymentCycle;
        uint16 APR;
        uint32 installments;
        uint32 installmentsPaid;
    }

    /**
     * @notice The base loan struct.
     * @param borrower The borrower of the loan.
     * @param receiver The receiver of the loan funds.
     * @param lender The lender of the loan funds.
     * @param poolId The Id of the pool in which the loan was created.
     * @param loanDetails The details of the loan.
     * @param terms The terms of the loan.
     * @param state The state of the loan.
     */
    struct Loan {
        address borrower;
        address receiver;
        address lender;
        uint256 poolId;
        LoanDetails loanDetails;
        Terms terms;
        LoanState state;
    }

    // Mapping of borrowers to borrower requests.
    mapping(address => EnumerableSet.UintSet) internal borrowerActiveLoans;

    // Amount filled by all lenders.
    // Asset address => Volume amount
    mapping(address => uint256) public totalERC20Amount;

    // Mapping of borrowers to borrower requests.
    mapping(address => uint256[]) public borrowerLoans;
    mapping(uint256 => uint32) public loanDefaultDuration;
    mapping(uint256 => uint32) public loanExpirationDuration;

    // Mapping of amount filled by lenders.
    // Asset address => Lender address => Lend amount
    mapping(address => mapping(address => uint256)) public lenderLendAmount;

    address public poolRegistryAddress;
    address public AconomyFeeAddress;

    //STORAGE END -----------------------------------------------------------------------------------------
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./AconomyFee.sol";
import "./Libraries/LibPool.sol";
import "./AttestationServices.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract poolRegistry is
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    //STORAGE START ------------------------------------------------------------------------------------

    AttestationServices public attestationService;
    bytes32 public lenderAttestationSchemaId;
    bytes32 public borrowerAttestationSchemaId;
    bytes32 private _attestingSchemaId;
    address public AconomyFeeAddress;
    address public FundingPoolAddress;
    //poolId => close or open
    mapping(uint256 => bool) private ClosedPools;

    uint256 public poolCount;

    /**
     * @notice Deatils for a pool.
     * @param poolAddress The address of the pool.
     * @param owner The owner of the pool.
     * @param URI The pool uri.
     * @param APR The desired apr of the pool.
     * @param poolFeePercent The pool fees in bps.
     * @param lenderAttestationRequired Boolean indicating the requirment of lender attestation.
     * @param verifiedLendersForPool The verified lenders of the pool.
     * @param lenderAttestationIds The Id's of the lender attestations.
     * @param paymentCycleDuration The duration of a payment cycle.
     * @param paymentDefaultDuration The duration after which the payment becomes defaulted.
     * @param loanExpirationTime The desired time after which the loan expires.
     * @param borrowerAttestationRequired Boolean indicating the requirment of borrower attestation.
     * @param verifiedBorrowersForPool The verified borrowers of the pool.
     * @param borrowerAttestationIds The Id's of the borrower attestations.
     */
    struct poolDetail {
        address poolAddress;
        address owner;
        string URI;
        uint16 APR;
        uint16 poolFeePercent; // 10000 is 100%
        bool lenderAttestationRequired;
        EnumerableSet.AddressSet verifiedLendersForPool;
        mapping(address => bytes32) lenderAttestationIds;
        uint32 paymentCycleDuration;
        uint32 paymentDefaultDuration;
        uint32 loanExpirationTime;
        bool borrowerAttestationRequired;
        EnumerableSet.AddressSet verifiedBorrowersForPool;
        mapping(address => bytes32) borrowerAttestationIds;
    }
    //poolId => poolDetail
    mapping(uint256 => poolDetail) internal pools;

    //STORAGE END ------------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        AttestationServices _attestationServices,
        address _AconomyFee,
        address _FundingPoolAddress
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        FundingPoolAddress = _FundingPoolAddress;
        attestationService = _attestationServices;
        AconomyFeeAddress = _AconomyFee;

        lenderAttestationSchemaId = _attestationServices
            .getASRegistry()
            .register("(uint256 poolId, address lenderAddress)");
        borrowerAttestationSchemaId = _attestationServices
            .getASRegistry()
            .register("(uint256 poolId, address borrowerAddress)");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier lenderOrBorrowerSchema(bytes32 schemaId) {
        _attestingSchemaId = schemaId;
        _;
        _attestingSchemaId = bytes32(0);
    }

    modifier ownsPool(uint256 _poolId) {
        require(pools[_poolId].owner == msg.sender, "Not the owner");
        _;
    }

    function changeFundingPoolImplementation(
        address newFundingPool
    ) external onlyOwner {
        FundingPoolAddress = newFundingPool;
    }

    event poolCreated(
        address indexed owner,
        address poolAddress,
        uint256 poolId
    );
    event SetPaymentCycleDuration(uint256 poolId, uint32 duration);
    event SetPaymentDefaultDuration(uint256 poolId, uint32 duration);
    event SetPoolFee(uint256 poolId, uint16 feePct);
    event SetloanExpirationTime(uint256 poolId, uint32 duration);
    event LenderAttestation(uint256 poolId, address lender);
    event BorrowerAttestation(uint256 poolId, address borrower);
    event LenderRevocation(uint256 poolId, address lender);
    event BorrowerRevocation(uint256 poolId, address borrower);
    event SetPoolURI(uint256 poolId, string uri);
    event SetAPR(uint256 poolId, uint16 APR);
    event poolClosed(uint256 poolId);

    /**
     * @notice Creates a new pool.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _loanExpirationTime Length of time in seconds before pending loan expire.
     * @param _poolFeePercent The pool fee percentage in bps.
     * @param _apr The desired pool apr.
     * @param _uri The pool uri.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join pool.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join pool.
     * @return poolId_ The market ID of the newly created pool.
     */
    function createPool(
        uint32 _paymentDefaultDuration,
        uint32 _loanExpirationTime,
        uint16 _poolFeePercent,
        uint16 _apr,
        string calldata _uri,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation
    ) external whenNotPaused returns (uint256 poolId_) {
        // Increment pool ID counter
        poolId_ = ++poolCount;

        //Deploy Pool Address
        address poolAddress = LibPool.deployPoolAddress(
            msg.sender,
            address(this),
            FundingPoolAddress
        );
        pools[poolId_].poolAddress = poolAddress;
        // Set the pool owner
        pools[poolId_].owner = msg.sender;

        setApr(poolId_, _apr);
        pools[poolId_].paymentCycleDuration = 30 days;
        setPaymentDefaultDuration(poolId_, _paymentDefaultDuration);
        setPoolFeePercent(poolId_, _poolFeePercent);
        setloanExpirationTime(poolId_, _loanExpirationTime);
        setPoolURI(poolId_, _uri);

        // Check if pool requires lender attestation to join
        if (_requireLenderAttestation) {
            pools[poolId_].lenderAttestationRequired = true;
            addLender(poolId_, msg.sender);
        }
        // Check if pool requires borrower attestation to join
        if (_requireBorrowerAttestation) {
            pools[poolId_].borrowerAttestationRequired = true;
            addBorrower(poolId_, msg.sender);
        }

        emit poolCreated(msg.sender, poolAddress, poolId_);
    }

    /**
     * @notice Sets the desired pool apr.
     * @param _poolId The Id of the pool.
     * @param _apr The apr to be set.
     */
    function setApr(uint256 _poolId, uint16 _apr) public ownsPool(_poolId) {
        require(_apr >= 100, "given apr too low");
        if (_apr != pools[_poolId].APR) {
            pools[_poolId].APR = _apr;

            emit SetAPR(_poolId, _apr);
        }
    }

    /**
     * @notice Sets the pool uri.
     * @param _poolId The Id of the pool.
     * @param _uri The uri to be set.
     */
    function setPoolURI(
        uint256 _poolId,
        string calldata _uri
    ) public ownsPool(_poolId) {
        if (
            keccak256(abi.encodePacked(_uri)) !=
            keccak256(abi.encodePacked(pools[_poolId].URI))
        ) {
            pools[_poolId].URI = _uri;

            emit SetPoolURI(_poolId, _uri);
        }
    }

    /**
     * @notice Sets the pool payment default duration.
     * @param _poolId The Id of the pool.
     * @param _duration The duration to be set.
     */
    function setPaymentDefaultDuration(
        uint256 _poolId,
        uint32 _duration
    ) public ownsPool(_poolId) {
        require(_duration != 0, "default duration cannot be 0");
        if (_duration != pools[_poolId].paymentDefaultDuration) {
            pools[_poolId].paymentDefaultDuration = _duration;

            emit SetPaymentDefaultDuration(_poolId, _duration);
        }
    }

    /**
     * @notice Sets the pool fee percent.
     * @param _poolId The Id of the pool.
     * @param _newPercent The new percent to be set.
     */
    function setPoolFeePercent(
        uint256 _poolId,
        uint16 _newPercent
    ) public ownsPool(_poolId) {
        require(_newPercent <= 1000, "cannot exceed 10%");
        if (_newPercent != pools[_poolId].poolFeePercent) {
            pools[_poolId].poolFeePercent = _newPercent;
            emit SetPoolFee(_poolId, _newPercent);
        }
    }

    /**
     * @notice Sets the desired loan expiration time.
     * @param _poolId The Id of the pool.
     * @param _duration the duration for expiration.
     */
    function setloanExpirationTime(
        uint256 _poolId,
        uint32 _duration
    ) public ownsPool(_poolId) {
        require(_duration != 0);
        if (_duration != pools[_poolId].loanExpirationTime) {
            pools[_poolId].loanExpirationTime = _duration;

            emit SetloanExpirationTime(_poolId, _duration);
        }
    }

    /**
     * @notice Change the details of existing pool.
     * @param _poolId The Id of the existing pool.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _loanExpirationTime Length of time in seconds before pending loan expire.
     * @param _poolFeePercent The pool fee percentage in bps.
     * @param _apr The desired pool apr.
     * @param _uri The pool uri.
     */
    function changePoolSetting(
        uint256 _poolId,
        uint32 _paymentDefaultDuration,
        uint32 _loanExpirationTime,
        uint16 _poolFeePercent,
        uint16 _apr,
        string calldata _uri
    ) public ownsPool(_poolId) {
        setApr(_poolId, _apr);
        setPaymentDefaultDuration(_poolId, _paymentDefaultDuration);
        setPoolFeePercent(_poolId, _poolFeePercent);
        setloanExpirationTime(_poolId, _loanExpirationTime);
        setPoolURI(_poolId, _uri);
    }

    /**
     * @notice Adds a lender to the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _lenderAddress The address of the lender.
     */
    function addLender(
        uint256 _poolId,
        address _lenderAddress
    ) public whenNotPaused ownsPool(_poolId) {
        require(pools[_poolId].lenderAttestationRequired);
        _attestAddress(_poolId, _lenderAddress, true);
    }

    /**
     * @notice Adds a borrower to the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _borrowerAddress The address of the borrower.
     */
    function addBorrower(
        uint256 _poolId,
        address _borrowerAddress
    ) public whenNotPaused ownsPool(_poolId) {
        require(pools[_poolId].borrowerAttestationRequired);
        _attestAddress(_poolId, _borrowerAddress, false);
    }

    /**
     * @notice Removes a lender from the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _lenderAddress The address of the lender.
     */
    function removeLender(
        uint256 _poolId,
        address _lenderAddress
    ) external whenNotPaused ownsPool(_poolId) {
        require(pools[_poolId].lenderAttestationRequired);
        _revokeAddress(_poolId, _lenderAddress, true);
    }

    /**
     * @notice Removes a borrower from the pool.
     * @dev Only called by the pool owner
     * @param _poolId The Id of the pool.
     * @param _borrowerAddress The address of the borrower.
     */
    function removeBorrower(
        uint256 _poolId,
        address _borrowerAddress
    ) external whenNotPaused ownsPool(_poolId) {
        require(pools[_poolId].borrowerAttestationRequired);
        _revokeAddress(_poolId, _borrowerAddress, false);
    }

    /**
     * @notice Attests an address.
     * @param _poolId The Id of the pool.
     * @param _Address The address being attested.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _attestAddress(
        uint256 _poolId,
        address _Address,
        bool _isLender
    )
        internal
        nonReentrant
        lenderOrBorrowerSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        require(msg.sender == pools[_poolId].owner, "Not the pool owner");

        // Submit attestation for borrower to join a pool
        bytes32 uuid = attestationService.attest(
            _Address,
            _attestingSchemaId, // set by the modifier
            abi.encode(_poolId, _Address)
        );

        _attestAddressVerification(_poolId, _Address, uuid, _isLender);
    }

    /**
     * @notice Verifies the address in poolRegistry.
     * @param _poolId The Id of the pool.
     * @param _Address The address being attested.
     * @param _uuid The uuid of the attestation.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _attestAddressVerification(
        uint256 _poolId,
        address _Address,
        bytes32 _uuid,
        bool _isLender
    ) internal {
        if (_isLender) {
            // Store the lender attestation ID for the pool ID
            pools[_poolId].lenderAttestationIds[_Address] = _uuid;
            // Add lender address to pool set
            require(
                pools[_poolId].verifiedLendersForPool.add(_Address),
                "add lender to poolfailed"
            );

            emit LenderAttestation(_poolId, _Address);
        } else {
            // Store the lender attestation ID for the pool ID
            pools[_poolId].borrowerAttestationIds[_Address] = _uuid;
            // Add lender address to pool set
            require(
                pools[_poolId].verifiedBorrowersForPool.add(_Address),
                "add borrower failed, verifiedBorrowersForPool.add failed"
            );

            emit BorrowerAttestation(_poolId, _Address);
        }
    }

    /**
     * @notice Revokes an address.
     * @param _poolId The Id of the pool.
     * @param _address The address being revoked.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _revokeAddress(
        uint256 _poolId,
        address _address,
        bool _isLender
    ) internal virtual {
        require(msg.sender == pools[_poolId].owner, "Not the pool owner");

        bytes32 uuid = _revokeAddressVerification(_poolId, _address, _isLender);

        attestationService.revoke(uuid);
    }

    /**
     * @notice Verifies the address being revoked in poolRegistry.
     * @param _poolId The Id of the pool.
     * @param _Address The address being revoked.
     * @param _isLender Boolean indicating if the address is a lender
     */
    function _revokeAddressVerification(
        uint256 _poolId,
        address _Address,
        bool _isLender
    ) internal virtual returns (bytes32 uuid_) {
        if (_isLender) {
            uuid_ = pools[_poolId].lenderAttestationIds[_Address];
            // Remove lender address from market set
            pools[_poolId].verifiedLendersForPool.remove(_Address);

            emit LenderRevocation(_poolId, _Address);
        } else {
            uuid_ = pools[_poolId].borrowerAttestationIds[_Address];
            // Remove borrower address from market set
            pools[_poolId].verifiedBorrowersForPool.remove(_Address);

            emit BorrowerRevocation(_poolId, _Address);
        }
    }

    function getPoolFee(uint256 _poolId) public view returns (uint16 fee) {
        return pools[_poolId].poolFeePercent;
    }

    /**
     * @notice Checks if the address is a verified borrower.
     * @dev returns a boolean and byte32 uuid.
     * @param _poolId The Id of the pool.
     * @param _borrowerAddress The address being verified.
     * @return isVerified_ boolean and byte32 uuid_.
     */
    function borrowerVerification(
        uint256 _poolId,
        address _borrowerAddress
    ) public view returns (bool isVerified_, bytes32 uuid_) {
        return
            _isAddressVerified(
                _borrowerAddress,
                pools[_poolId].borrowerAttestationRequired,
                pools[_poolId].borrowerAttestationIds,
                pools[_poolId].verifiedBorrowersForPool
            );
    }

    /**
     * @notice Checks if the address is a verified lender.
     * @dev returns a boolean and byte32 uuid.
     * @param _poolId The Id of the pool.
     * @param _lenderAddress The address being verified.
     * @return isVerified_ boolean and byte32 uuid_.
     */
    function lenderVerification(
        uint256 _poolId,
        address _lenderAddress
    ) public view returns (bool isVerified_, bytes32 uuid_) {
        return
            _isAddressVerified(
                _lenderAddress,
                pools[_poolId].lenderAttestationRequired,
                pools[_poolId].lenderAttestationIds,
                pools[_poolId].verifiedLendersForPool
            );
    }

    /**
     * @notice Checks if the address is verified.
     * @dev returns a boolean and byte32 uuid.
     * @param _wltAddress The address being checked.
     * @param _attestationRequired The need for attestation for the pool.
     * @param _stakeholderAttestationIds The uuid's of the verified pool addresses
     * @param _verifiedStakeholderForPool The addresses of the pool
     * @return isVerified_ boolean and byte32 uuid_.
     */
    function _isAddressVerified(
        address _wltAddress,
        bool _attestationRequired,
        mapping(address => bytes32) storage _stakeholderAttestationIds,
        EnumerableSet.AddressSet storage _verifiedStakeholderForPool
    ) internal view returns (bool isVerified_, bytes32 uuid_) {
        if (_attestationRequired) {
            isVerified_ =
                _verifiedStakeholderForPool.contains(_wltAddress) &&
                attestationService.isAddressActive(
                    _stakeholderAttestationIds[_wltAddress]
                );
            uuid_ = _stakeholderAttestationIds[_wltAddress];
        } else {
            isVerified_ = true;
        }
    }

    /**
     * @notice Closes the pool specified.
     * @param _poolId The Id of the pool.
     */
    function closePool(uint256 _poolId) public whenNotPaused ownsPool(_poolId) {
        if (!ClosedPools[_poolId]) {
            ClosedPools[_poolId] = true;

            emit poolClosed(_poolId);
        }
    }

    function ClosedPool(uint256 _poolId) public view returns (bool) {
        return ClosedPools[_poolId];
    }

    function getPaymentCycleDuration(
        uint256 _poolId
    ) public view returns (uint32) {
        return pools[_poolId].paymentCycleDuration;
    }

    function getPaymentDefaultDuration(
        uint256 _poolId
    ) public view returns (uint32) {
        return pools[_poolId].paymentDefaultDuration;
    }

    function getloanExpirationTime(
        uint256 poolId
    ) public view returns (uint32) {
        return pools[poolId].loanExpirationTime;
    }

    function getPoolAddress(uint256 _poolId) public view returns (address) {
        return pools[_poolId].poolAddress;
    }

    function getPoolOwner(uint256 _poolId) public view returns (address) {
        return pools[_poolId].owner;
    }

    function getPoolApr(uint256 _poolId) public view returns (uint16) {
        return pools[_poolId].APR;
    }

    function getPoolFeePercent(uint256 _poolId) public view returns (uint16) {
        return pools[_poolId].poolFeePercent;
    }

    function getAconomyFee() public view returns (uint16) {
        return AconomyFee(AconomyFeeAddress).AconomyPoolFee();
    }

    function getAconomyOwner() public view returns (address) {
        return AconomyFee(AconomyFeeAddress).getAconomyOwnerAddress();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./poolRegistry.sol";
import "./poolStorage.sol";
import "./AconomyFee.sol";
import "./Libraries/LibCalculations.sol";
import "./Libraries/LibPoolAddress.sol";
import {BokkyPooBahsDateTimeLibrary as BPBDTL} from "./Libraries/DateTimeLib.sol";

contract poolAddress is
    poolStorage,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _poolRegistry,
        address _AconomyFeeAddress
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        poolRegistryAddress = _poolRegistry;
        AconomyFeeAddress = _AconomyFeeAddress;
        loanId = 0;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    event loanAccepted(uint256 indexed loanId, address indexed lender);

    event repaidAmounts(
        uint256 owedPrincipal,
        uint256 duePrincipal,
        uint256 interest
    );
    event AcceptedLoanDetail(
        uint256 indexed loanId,
        string indexed feeType,
        uint256 indexed amount
    );

    event LoanRepaid(uint256 indexed loanId, uint256 Amount);
    event LoanRepayment(uint256 indexed loanId, uint256 Amount);

    event SubmittedLoan(
        uint256 indexed loanId,
        address indexed borrower,
        address receiver,
        uint256 paymentCycleAmount
    );

    /**
     * @notice Lets a borrower request for a loan.
     * @dev Returned value is type uint256.
     * @param _lendingToken The address of the token being requested.
     * @param _poolId The Id of the pool.
     * @param _principal The principal amount being requested.
     * @param _duration The duration of the loan.
     * @param _expirationDuration The time in which the loan has to be accepted before it expires.
     * @param _APR The annual interest percentage in bps.
     * @param _receiver The receiver of the funds.
     * @return loanId_ Id of the loan.
     */
    function loanRequest(
        address _lendingToken,
        uint256 _poolId,
        uint256 _principal,
        uint32 _duration,
        uint32 _expirationDuration,
        uint16 _APR,
        address _receiver
    ) public whenNotPaused returns (uint256 loanId_) {
        require(_lendingToken != address(0));
        require(_receiver != address(0));
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .borrowerVerification(_poolId, msg.sender);
        require(isVerified);
        require(!poolRegistry(poolRegistryAddress).ClosedPool(_poolId));
        require(_duration % 30 days == 0);
        require(_APR >= 100);
        require(_principal >= 1000000, "low");
        require(_expirationDuration > 0);

        loanId_ = loanId;

        poolLoans[_poolId] = loanId_;

        uint16 fee = AconomyFee(AconomyFeeAddress).AconomyPoolFee();

        // Create and store our loan into the mapping
        Loan storage loan = loans[loanId];
        loan.borrower = msg.sender;
        loan.receiver = _receiver != address(0) ? _receiver : loan.borrower;
        loan.poolId = _poolId;
        loan.loanDetails.lendingToken = ERC20(_lendingToken);
        loan.loanDetails.principal = _principal;
        loan.loanDetails.loanDuration = _duration;
        loan.loanDetails.timestamp = uint32(block.timestamp);
        loan.loanDetails.protocolFee = fee;
        loan.terms.installments = _duration / 30 days;
        loan.terms.installmentsPaid = 0;

        loan.terms.paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        loan.terms.APR = _APR;

        loanDefaultDuration[loanId] = poolRegistry(poolRegistryAddress)
            .getPaymentDefaultDuration(_poolId);

        loanExpirationDuration[loanId] = _expirationDuration;

        loan.terms.paymentCycleAmount = LibCalculations.payment(
            _principal,
            _duration,
            loan.terms.paymentCycle,
            _APR
        );

        uint256 monthlyPrincipal = _principal / loan.terms.installments;

        loan.terms.monthlyCycleInterest =
            loan.terms.paymentCycleAmount -
            monthlyPrincipal;

        loan.state = LoanState.PENDING;

        emit SubmittedLoan(
            loanId,
            loan.borrower,
            loan.receiver,
            loan.terms.paymentCycleAmount
        );

        // Store loan inside borrower loans mapping
        borrowerLoans[loan.borrower].push(loanId);

        // Increment loan id
        loanId++;
    }

    /**
     * @notice Accepts the loan request.
     * @param _loanId The Id of the loan.
     */
    function AcceptLoan(
        uint256 _loanId
    )
        external
        whenNotPaused
        nonReentrant
        returns (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        )
    {
        Loan storage loan = loans[_loanId];
        require(!isLoanExpired(_loanId));

        (amountToAconomy, amountToPool, amountToBorrower) = LibPoolAddress
            .acceptLoan(loan, poolRegistryAddress, AconomyFeeAddress);

        // Record Amount filled by lenders
        lenderLendAmount[address(loan.loanDetails.lendingToken)][
            loan.lender
        ] += loan.loanDetails.principal;
        totalERC20Amount[address(loan.loanDetails.lendingToken)] += loan
            .loanDetails
            .principal;

        // Store Borrower's active loan
        require(borrowerActiveLoans[loan.borrower].add(_loanId));

        emit loanAccepted(_loanId, loan.lender);

        emit AcceptedLoanDetail(_loanId, "protocol", amountToAconomy);
        emit AcceptedLoanDetail(_loanId, "Pool", amountToPool);
        emit AcceptedLoanDetail(_loanId, "Borrower", amountToBorrower);
    }

    /**
     * @notice Checks if the loan has expired.
     * @dev Return type is of boolean.
     * @param _loanId The Id of the loan.
     * @return boolean indicating if the loan is expired.
     */
    function isLoanExpired(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];

        if (loan.state != LoanState.PENDING) return false;
        if (loanExpirationDuration[_loanId] == 0) return false;

        return (uint32(block.timestamp) >
            loan.loanDetails.timestamp + loanExpirationDuration[_loanId]);
    }

    /**
     * @notice Checks if the loan has defaulted.
     * @dev Return type is of boolean.
     * @param _loanId The Id of the loan.
     * @return boolean indicating if the loan is defaulted.
     */
    function isLoanDefaulted(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];

        // Make sure loan cannot be liquidated if it is not active
        if (loan.state != LoanState.ACCEPTED) return false;

        if (loanDefaultDuration[_loanId] == 0) return false;

        return ((int32(uint32(block.timestamp)) -
            int32(
                loan.loanDetails.acceptedTimestamp +
                    loan.loanDetails.loanDuration
            )) > int32(loanDefaultDuration[_loanId]));
    }

    /**
     * @notice Returns the last repaid timestamp of the loan.
     * @dev Return type is of uint32.
     * @param _loanId The Id of the loan.
     * @return timestamp in uint32.
     */
    function lastRepaidTimestamp(uint256 _loanId) public view returns (uint32) {
        return LibCalculations.lastRepaidTimestamp(loans[_loanId]);
    }

    /**
     * @notice Checks if the loan repayment is late.
     * @dev Return type is of boolean.
     * @param _loanId The Id of the loan.
     * @return boolean indicating if the loan repayment is late.
     */
    function isPaymentLate(uint256 _loanId) public view returns (bool) {
        if (loans[_loanId].state != LoanState.ACCEPTED) return false;
        return uint32(block.timestamp) > calculateNextDueDate(_loanId) + 7 days;
    }

    /**
     * @notice Calculates the next repayment due date.
     * @dev Return type is of uint32.
     * @param _loanId The Id of the loan.
     * @return dueDate_ The timestamp of the next payment due date.
     */
    function calculateNextDueDate(
        uint256 _loanId
    ) public view returns (uint32 dueDate_) {
        Loan storage loan = loans[_loanId];
        if (loans[_loanId].state != LoanState.ACCEPTED) return dueDate_;

        // Start with the original due date being 1 payment cycle since loan was accepted
        dueDate_ = loan.loanDetails.acceptedTimestamp + loan.terms.paymentCycle;

        // Calculate the cycle number the last repayment was made
        uint32 delta = lastRepaidTimestamp(_loanId) -
            loan.loanDetails.acceptedTimestamp;
        if (delta > 0) {
            uint32 repaymentCycle = (delta / loan.terms.paymentCycle);
            dueDate_ += (repaymentCycle * loan.terms.paymentCycle);
        }

        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (
            dueDate_ >
            loan.loanDetails.acceptedTimestamp + loan.loanDetails.loanDuration
        ) {
            dueDate_ =
                loan.loanDetails.acceptedTimestamp +
                loan.loanDetails.loanDuration;
        }
    }

    /**
     * @notice Returns the installment amount to be paid at the called timestamp.
     * @dev Return type is of uint256.
     * @param _loanId The Id of the loan.
     * @return uint256 of the installment amount to be paid.
     */
    function viewInstallmentAmount(
        uint256 _loanId
    ) external view returns (uint256) {
        uint32 LastRepaidTimestamp = lastRepaidTimestamp(_loanId);
        uint256 lastPaymentCycle = BPBDTL.diffMonths(
            loans[_loanId].loanDetails.acceptedTimestamp,
            LastRepaidTimestamp
        );
        uint256 monthsSinceStart = BPBDTL.diffMonths(
            loans[_loanId].loanDetails.acceptedTimestamp,
            block.timestamp
        );

        if (
            loans[_loanId].terms.installmentsPaid + 1 ==
            loans[_loanId].terms.installments
        ) {
            return viewFullRepayAmount(_loanId);
        }

        if (monthsSinceStart > lastPaymentCycle) {
            return loans[_loanId].terms.paymentCycleAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Repays the monthly installment.
     * @param _loanId The Id of the loan.
     */
    function repayMonthlyInstallment(
        uint256 _loanId
    ) external whenNotPaused nonReentrant {
        require(loans[_loanId].loanDetails.principal / uint256(loans[_loanId].terms.installments) >= 1000000, "low");
        require(loans[_loanId].state == LoanState.ACCEPTED);
        require(
            loans[_loanId].terms.installmentsPaid + 1 <=
                loans[_loanId].terms.installments
        );
        require(block.timestamp > calculateNextDueDate(_loanId));

        if (
            loans[_loanId].terms.installmentsPaid + 1 ==
            loans[_loanId].terms.installments
        ) {
            _repayFullLoan(_loanId);
        } else {
            uint256 monthlyInterest = loans[_loanId].terms.monthlyCycleInterest;
            uint256 monthlyDue = loans[_loanId].terms.paymentCycleAmount;
            uint256 due = monthlyDue - monthlyInterest;

            (uint256 owedAmount, , uint256 interest) = LibCalculations
                .owedAmount(loans[_loanId], block.timestamp);
            loans[_loanId].terms.installmentsPaid++;

            _repayLoan(
                _loanId,
                Payment({principal: due, interest: monthlyInterest}),
                owedAmount + interest
            );
            loans[_loanId].loanDetails.lastRepaidTimestamp =
                loans[_loanId].loanDetails.acceptedTimestamp +
                (loans[_loanId].terms.installmentsPaid *
                    loans[_loanId].terms.paymentCycle);
        }
    }

    /**
     * @notice Returns the full amount to be paid at the called timestamp.
     * @dev Return type is of uint256.
     * @param _loanId The Id of the loan.
     * @return uint256 of the full amount to be paid.
     */
    function viewFullRepayAmount(
        uint256 _loanId
    ) public view returns (uint256) {
        (uint256 owedAmount, , uint256 interest) = LibCalculations.owedAmount(
            loans[_loanId],
            block.timestamp + 10 minutes
        );

        uint256 paymentAmount = owedAmount + interest;
        if (
            loans[_loanId].state != LoanState.ACCEPTED ||
            loans[_loanId].state == LoanState.PAID
        ) {
            paymentAmount = 0;
        }
        return paymentAmount;
    }

    /**
     * @notice Repays the full amount to be paid at the called timestamp.
     * @param _loanId The Id of the loan.
     */
    function _repayFullLoan(uint256 _loanId) private {
        require(loans[_loanId].state == LoanState.ACCEPTED);
        (uint256 owedPrincipal, , uint256 interest) = LibCalculations
            .owedAmount(loans[_loanId], block.timestamp);
        _repayLoan(
            _loanId,
            Payment({principal: owedPrincipal, interest: interest}),
            owedPrincipal + interest
        );
    }

    /**
     * @notice Repays the full amount to be paid at the called timestamp.
     * @param _loanId The Id of the loan.
     */
    function repayFullLoan(
        uint256 _loanId
    ) external nonReentrant whenNotPaused {
        require(loans[_loanId].state == LoanState.ACCEPTED);
        (uint256 owedPrincipal, , uint256 interest) = LibCalculations
            .owedAmount(loans[_loanId], block.timestamp);
        _repayLoan(
            _loanId,
            Payment({principal: owedPrincipal, interest: interest}),
            owedPrincipal + interest
        );
    }

    /**
     * @notice Repays the specified amount.
     * @param _loanId The Id of the loan.
     * @param _payment The amount being paid split into principal and interest.
     * @param _owedAmount The total amount owed at the called timestamp.
     */
    function _repayLoan(
        uint256 _loanId,
        Payment memory _payment,
        uint256 _owedAmount
    ) internal {
        Loan storage loan = loans[_loanId];
        uint256 paymentAmount = _payment.principal + _payment.interest;

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;
            loan.state = LoanState.PAID;

            // Remove borrower's active loan
            require(borrowerActiveLoans[loan.borrower].remove(_loanId));

            emit LoanRepaid(_loanId, paymentAmount);
        } else {
            emit LoanRepayment(_loanId, paymentAmount);
        }

        loan.loanDetails.totalRepaid.principal += _payment.principal;
        loan.loanDetails.totalRepaid.interest += _payment.interest;
        loan.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        // Send payment to the lender
        bool isSuccess = IERC20(loan.loanDetails.lendingToken).transferFrom(
            msg.sender,
            loan.lender,
            paymentAmount
        );

        require(isSuccess);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

interface IAttestationServices {
    function register(bytes calldata schema) external returns (bytes32);
}

pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

interface IAttestationRegistry {

    /**
     * @title A struct representing a record for a submitted AS (Attestation Schema).
     */
    struct ASRecord {
        // A unique identifier of the Attestation Registry.
        bytes32 uuid;
        // Auto-incrementing index for reference, assigned by the registry itself.
        uint256 index;
        // Custom specification of the Attestation Registry (e.g., an ABI).
        bytes schema;
    }

    /**
     * @dev Submits and reserve a new AS
     *
     * @param schema The AS data schema.
     *
     * @return The UUID of the new AS.
     */
    function register(bytes calldata schema) external returns (bytes32);

     /**
     * @dev Returns an existing AS by UUID
     *
     * @param uuid The UUID of the AS to retrieve.
     *
     * @return The AS data members.
     */
    function getAS(bytes32 uuid) external view returns (ASRecord memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */
library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function pctToWad(uint16 a) internal pure returns (uint256) {
        return uint256(a).mul(WAD).div(1e4);
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function wadPow(uint256 x, uint256 n) internal pure returns (uint256) {
        return _pow(x, n, WAD, wadMul);
    }

    function _pow(
        uint256 x,
        uint256 n,
        uint256 p,
        function(uint256, uint256) internal pure returns (uint256) mul
    ) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : p;

        for (n /= 2; n != 0; n /= 2) {
            x = mul(x, x);

            if (n % 2 != 0) {
                z = mul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../poolStorage.sol";
import "../poolRegistry.sol";
import "../AconomyFee.sol";
import "./LibCalculations.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibPoolAddress {

    function acceptLoan(poolStorage.Loan storage loan, address poolRegistryAddress, address AconomyFeeAddress) 
    external 
    returns (
            uint256 amountToAconomy,
            uint256 amountToPool,
            uint256 amountToBorrower
        )
    {
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .lenderVerification(loan.poolId, msg.sender);

        require(isVerified, "Not verified lender");
        require(loan.state == poolStorage.LoanState.PENDING, "loan not pending");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(loan.poolId),
            "pool closed"
        );
        // require(!isLoanExpired(_loanId));

        loan.loanDetails.acceptedTimestamp = uint32(block.timestamp);
        loan.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        loan.state = poolStorage.LoanState.ACCEPTED;

        loan.lender = msg.sender;

        //Aconomy Fee
        amountToAconomy = LibCalculations.percent(
            loan.loanDetails.principal,
            loan.loanDetails.protocolFee
        );

        //Pool Fee
        amountToPool = LibCalculations.percent(
            loan.loanDetails.principal,
            poolRegistry(poolRegistryAddress).getPoolFee(loan.poolId)
        );

        //Amount to Borrower
        amountToBorrower =
            loan.loanDetails.principal -
            amountToAconomy -
            amountToPool;

        //Transfer Aconomy Fee
        if (amountToAconomy != 0) {
            bool isSuccess = IERC20(loan.loanDetails.lendingToken).transferFrom(
                loan.lender,
                AconomyFee(AconomyFeeAddress).getAconomyOwnerAddress(),
                amountToAconomy
            );
            require(isSuccess, "aconomy transfer failed");
        }

        //Transfer to Pool Owner
        if (amountToPool != 0) {
            bool isSuccess2 = IERC20(loan.loanDetails.lendingToken)
                .transferFrom(
                    loan.lender,
                    poolRegistry(poolRegistryAddress).getPoolOwner(loan.poolId),
                    amountToPool
                );
            require(isSuccess2, "pool transfer failed");
        }

        //transfer funds to borrower
        bool isSuccess3 = IERC20(loan.loanDetails.lendingToken).transferFrom(
            loan.lender,
            loan.borrower,
            amountToBorrower
        );

        require(isSuccess3, "borrower transfer failed");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../FundingPool.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

library LibPool {

    /**
     * @notice Returns the address of the deployed pool contract.
     * @dev Returned value is type address.
     * @param _poolOwner The address set to own the pool.
     * @param _poolRegistry The address of the poolRegistry contract.
     * @param _FundingPool the address of the proxy implementation of FundingPool.
     * @return address of the deployed .
     */
    function deployPoolAddress(
        address _poolOwner,
        address _poolRegistry,
        address _FundingPool
    ) external returns (address) {
        address tokenAddress = Clones.clone(_FundingPool);
        FundingPool(tokenAddress).initialize(_poolOwner, _poolRegistry);

        return address(tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFTlendingBorrowing.sol";
import "./LibCalculations.sol";

library LibNFTLendingBorrowing {
    function acceptBid(
        NFTlendingBorrowing.NFTdetail storage nftDetail, 
        NFTlendingBorrowing.BidDetail storage bidDetail, 
        uint256 amountToAconomy,
        address aconomyOwner
        ) external {
        require(!bidDetail.withdrawn, "Already withdrawn");
        require(nftDetail.listed, "It's not listed for Borrowing");
        require(!nftDetail.bidAccepted, "bid already accepted");
        require(!bidDetail.bidAccepted, "Bid Already Accepted");
        require(bidDetail.expiration > block.timestamp, "Bid is expired");
        require(
            nftDetail.tokenIdOwner == msg.sender,
            "You can't Accept This Bid"
        );

        nftDetail.bidAccepted = true;
        bidDetail.bidAccepted = true;
        bidDetail.acceptedTimestamp = block.timestamp;

        // transfering Amount to NFT Owner
        require(
            IERC20(bidDetail.ERC20Address).transfer(
                msg.sender,
                bidDetail.Amount - amountToAconomy
            ),
            "unable to transfer to receiver"
        );

        // transfering Amount to Protocol Owner
        if (amountToAconomy != 0) {
            require(
                IERC20(bidDetail.ERC20Address).transfer(
                    aconomyOwner,
                    amountToAconomy
                ),
                "Unable to transfer to AconomyOwner"
            );
        }

        //needs approval on frontend
        // transferring NFT to this address
        ERC721(nftDetail.contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftDetail.NFTtokenId
        );
    }

    function RejectBid(
        NFTlendingBorrowing.NFTdetail storage nftDetail, 
        NFTlendingBorrowing.BidDetail storage bidDetail
    ) external {
        require(!bidDetail.withdrawn, "Already withdrawn");
        require(!bidDetail.bidAccepted, "Bid Already Accepted");
        require(bidDetail.expiration > block.timestamp, "Bid is expired");
        require(
            nftDetail.tokenIdOwner == msg.sender,
            "You can't Reject This Bid"
        );
        bidDetail.withdrawn = true;
        require(
            IERC20(bidDetail.ERC20Address).transfer(
                bidDetail.bidderAddress,
                bidDetail.Amount
            ),
            "unable to transfer to bidder Address"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./WadRayMath.sol";
import "../poolAddress.sol";

library LibCalculations {
    using WadRayMath for uint256;

    uint256 internal constant WAD = 1e18;

    function percentFactor(uint256 decimals) internal pure returns (uint256) {
        return 100 * (10**decimals);
    }

    /**
     * Returns a percentage value of a number.
     self The number to get a percentage of.
     percentage The percentage value to calculate with 2 decimal places (10000 = 100%).
     */
    function percent(uint256 self, uint16 percentage)
        public
        pure
        returns (uint256)
    {
        return percent(self, percentage, 2);
    }

    /**
     * Returns a percentage value of a number.
     self The number to get a percentage of.
     percentage The percentage value to calculate with.
     decimals The number of decimals the percentage value is in.
     */
    function percent(
        uint256 self,
        uint256 percentage,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (self * percentage) / percentFactor(decimals);
    }

    function payment(
        uint256 principal,
        uint32 loanDuration,
        uint32 cycleDuration,
        uint16 apr
    ) public pure returns (uint256) {
        require(
            loanDuration >= cycleDuration,
            "cycle < duration"
        );
        if (apr == 0)
            return
                Math.mulDiv(
                    principal,
                    cycleDuration,
                    loanDuration,
                    Math.Rounding.Up
                );

        // Number of payment cycles for the duration of the loan
        uint256 n = Math.ceilDiv(loanDuration, cycleDuration);

        uint256 one = WadRayMath.wad();
        uint256 r = WadRayMath.pctToWad(apr).wadMul(cycleDuration).wadDiv(
            360 days
        );
        uint256 exp = (one + r).wadPow(n);
        uint256 numerator = principal.wadMul(r).wadMul(exp);
        uint256 denominator = exp - one;

        return numerator.wadDiv(denominator);
    }

    function lastRepaidTimestamp(poolAddress.Loan storage _loan)
        internal
        view
        returns (uint32)
    {
        return
            _loan.loanDetails.lastRepaidTimestamp == 0
                ? _loan.loanDetails.acceptedTimestamp
                : _loan.loanDetails.lastRepaidTimestamp;
    }

    function calculateInstallmentAmount(
        uint256 amount,
        uint256 leftAmount,
        uint16 interestRate,
        uint256 paymentCycleAmount,
        uint256 paymentCycle,
        uint32 _lastRepaidTimestamp,
        uint256 timestamp,
        uint256 acceptBidTimestamp,
        uint256 maxDuration
    )
        internal
        pure
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        return
            calculateOwedAmount(
                amount,
                leftAmount,
                interestRate,
                paymentCycleAmount,
                paymentCycle,
                _lastRepaidTimestamp,
                timestamp,
                acceptBidTimestamp,
                maxDuration
            );
    }

    function owedAmount(poolAddress.Loan storage _loan, uint256 _timestamp)
        internal
        view
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        // Total Amount left to pay
        return
            calculateOwedAmount(
                _loan.loanDetails.principal,
                _loan.loanDetails.totalRepaid.principal,
                _loan.terms.APR,
                _loan.terms.paymentCycleAmount,
                _loan.terms.paymentCycle,
                lastRepaidTimestamp(_loan),
                _timestamp,
                _loan.loanDetails.acceptedTimestamp,
                _loan.loanDetails.loanDuration
            );
    }

    function calculateOwedAmount(
        uint256 principal,
        uint256 totalRepaidPrincipal,
        uint16 _interestRate,
        uint256 _paymentCycleAmount,
        uint256 _paymentCycle,
        uint256 _lastRepaidTimestamp,
        uint256 _timestamp,
        uint256 _startTimestamp,
        uint256 _loanDuration
    )
        internal
        pure
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        owedPrincipal_ = principal - totalRepaidPrincipal;

        uint256 interestInAYear = percent(owedPrincipal_, _interestRate);
        uint256 owedTime = _timestamp - uint256(_lastRepaidTimestamp);
        uint256 owedTimeInHours = owedTime / 3600;
        uint256 oneYearInHours = 360 days / 3600;
        interest_ = (interestInAYear * owedTimeInHours) / oneYearInHours;

        // Cast to int265 to avoid underflow errors (negative means loan duration has passed)
        int256 durationLeftOnLoan = int256(uint256(_loanDuration)) -
            (int256(_timestamp) - int256(uint256(_startTimestamp)));
        bool isLastPaymentCycle = durationLeftOnLoan < int256(uint256(_paymentCycle)) || // Check if current payment cycle is within or beyond the last one
            owedPrincipal_ + interest_ <= _paymentCycleAmount; // Check if what is left to pay is less than the payment cycle amount

        // Max payable amount in a cycle
        // NOTE: the last cycle could have less than the calculated payment amount
        uint256 maxCycleOwed = isLastPaymentCycle
            ? owedPrincipal_ + interest_
            : _paymentCycleAmount;

        // Calculate accrued amount due since last repayment
        uint256 Amount = (maxCycleOwed * owedTime) / _paymentCycle;
        duePrincipal_ = Math.min(Amount - interest_, owedPrincipal_);
    }

    function calculateInterest(uint256 _owedPrincipal, uint16 _interestRate, uint256 _owedTime) internal pure returns(uint256 _interest) {
        uint256 interestInAYear = percent(_owedPrincipal, _interestRate);
        uint256 owedTimeInHours = _owedTime / 3600;
        uint256 oneYearInHours = 360 days / 3600;
        _interest = (interestInAYear * owedTimeInHours) / oneYearInHours;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day)
        internal
        pure
        returns (uint _days)
    {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days)
        internal
        pure
        returns (uint year, uint month, uint day)
    {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day)
        internal
        pure
        returns (uint timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint year,
        uint month,
        uint day,
        uint hour,
        uint minute,
        uint second
    ) internal pure returns (uint timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint timestamp)
        internal
        pure
        returns (uint year, uint month, uint day)
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint timestamp)
        internal
        pure
        returns (
            uint year,
            uint month,
            uint day,
            uint hour,
            uint minute,
            uint second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day)
        internal
        pure
        returns (bool valid)
    {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint year,
        uint month,
        uint day,
        uint hour,
        uint minute,
        uint second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint timestamp)
        internal
        pure
        returns (uint daysInMonth)
    {
        (uint year, uint month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint year, uint month)
        internal
        pure
        returns (uint daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp)
        internal
        pure
        returns (uint dayOfWeek)
    {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint timestamp) internal pure returns (uint month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint timestamp) internal pure returns (uint day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years)
        internal
        pure
        returns (uint newTimestamp)
    {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint timestamp, uint _months)
        internal
        pure
        returns (uint newTimestamp)
    {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint timestamp, uint _days)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint timestamp, uint _hours)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint timestamp, uint _minutes)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint timestamp, uint _seconds)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years)
        internal
        pure
        returns (uint newTimestamp)
    {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint timestamp, uint _months)
        internal
        pure
        returns (uint newTimestamp)
    {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint timestamp, uint _days)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint timestamp, uint _hours)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint timestamp, uint _minutes)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint timestamp, uint _seconds)
        internal
        pure
        returns (uint newTimestamp)
    {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp)
        internal
        pure
        returns (uint _years)
    {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp)
        internal
        pure
        returns (uint _months)
    {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth, ) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (uint toYear, uint toMonth, ) = _daysToDate(
            toTimestamp / SECONDS_PER_DAY
        );
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint fromTimestamp, uint toTimestamp)
        internal
        pure
        returns (uint _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint fromTimestamp, uint toTimestamp)
        internal
        pure
        returns (uint _hours)
    {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp)
        internal
        pure
        returns (uint _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint fromTimestamp, uint toTimestamp)
        internal
        pure
        returns (uint _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Libraries/LibPool.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Libraries/LibCalculations.sol";
import "./poolRegistry.sol";
import {BokkyPooBahsDateTimeLibrary as BPBDTL} from "./Libraries/DateTimeLib.sol";

contract FundingPool is Initializable, ReentrancyGuardUpgradeable {
    address public poolOwner;
    address public poolRegistryAddress;

    /**
     * @notice Initializer function.
     * @param _poolOwner The pool owner's address.
     * @param _poolRegistry The address of the poolRegistry contract.
     */
    function initialize(
        address _poolOwner,
        address _poolRegistry
    ) external initializer {
        poolOwner = _poolOwner;
        poolRegistryAddress = _poolRegistry;
    }

    uint256 public bidId = 0;

    event BidRepaid(uint256 indexed bidId, uint256 PaidAmount);
    event BidRepayment(uint256 indexed bidId, uint256 PaidAmount);

    event BidAccepted(
        address lender,
        address reciever,
        uint256 BidId,
        uint256 PoolId,
        uint256 Amount,
        uint256 paymentCycleAmount
    );

    event BidRejected(
        address lender,
        uint256 BidId,
        uint256 PoolId,
        uint256 Amount
    );

    event Withdrawn(
        address reciever,
        uint256 BidId,
        uint256 PoolId,
        uint256 Amount
    );

    event SuppliedToPool(
        address indexed lender,
        uint256 indexed poolId,
        uint256 BidId,
        address indexed ERC20Token,
        uint256 tokenAmount
    );

    event InstallmentRepaid(
        uint256 poolId,
        uint256 bidId,
        uint256 owedAmount,
        uint256 dueAmount,
        uint256 interest
    );

    event FullAmountRepaid(
        uint256 poolId,
        uint256 bidId,
        uint256 Amount,
        uint256 interest
    );

    /**
     * @notice Deatils for the installments.
     * @param monthlyCycleInterest The interest to be paid every cycle.
     * @param installments The total installments to be paid.
     * @param installmentsPaid The total installments paid.
     * @param defaultDuration The duration after which loan is defaulted
     * @param protocolFee The protocol fee when creating the bid.
     */
    struct Installments {
        uint256 monthlyCycleInterest;
        uint32 installments;
        uint32 installmentsPaid;
        uint32 defaultDuration;
        uint16 protocolFee;
    }

    /**
     * @notice Deatils for a fund supply.
     * @param amount The amount being funded.
     * @param expiration The timestamp within which the fund bid should be accepted.
     * @param maxDuration The bid loan duration.
     * @param interestRate The interest rate in bps.
     * @param state The state of the bid.
     * @param bidTimestamp The timestamp the bid was created.
     * @param acceptBidTimestamp The timestamp the bid was accepted.
     * @param paymentCycleAmount The amount to be paid every cycle.
     * @param totalRepaidPrincipal The total principal repaid.
     * @param lastRepaidTimestamp The timestamp of the last repayment.
     * @param installment The installment details.
     * @param repaid The amount repaid.
     */
    struct FundDetail {
        uint256 amount;
        uint256 expiration; //After expiration time, if owner dose not accept bid then lender can withdraw the fund
        uint32 maxDuration; //Bid Duration
        uint16 interestRate;
        BidState state;
        uint32 bidTimestamp;
        uint32 acceptBidTimestamp;
        uint256 paymentCycleAmount;
        uint256 totalRepaidPrincipal;
        uint32 lastRepaidTimestamp;
        Installments installment;
        RePayment Repaid;
    }

    /**
     * @notice Deatils for payment.
     * @param amount The principal amount involved.
     * @param interest The interest amount involved.
     */
    struct RePayment {
        uint256 amount;
        uint256 interest;
    }

    enum BidState {
        PENDING,
        ACCEPTED,
        PAID,
        WITHDRAWN,
        REJECTED
    }

    // Mapping of lender address => poolId => ERC20 token => BidId => FundDetail
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => FundDetail))))
        public lenderPoolFundDetails;

    /**
     * @notice Allows a lender to supply funds to the pool owner.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds being supplied.
     * @param _amount The amount of funds being supplied.
     * @param _maxLoanDuration The duration of the loan after being accepted.
     * @param _expiration The time stamp within which the loan has to be accepted.
     * @param _APR The annual interest in bps
     */
    function supplyToPool(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _amount,
        uint32 _maxLoanDuration,
        uint256 _expiration,
        uint16 _APR
    ) external nonReentrant {
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "pool closed"
        );
        (bool isVerified, ) = poolRegistry(poolRegistryAddress)
            .lenderVerification(_poolId, msg.sender);

        require(isVerified, "Not verified lender");

        require(
            _ERC20Address != address(0),
            "you can't do this with zero address"
        );

        require(_maxLoanDuration % 30 days == 0);
        require(_APR >= 100, "apr too low");
        require(_amount >= 1000000, "amount too low");

        uint16 fee = poolRegistry(poolRegistryAddress).getAconomyFee();

        require(_expiration > uint32(block.timestamp), "wrong timestamp");
        uint256 _bidId = bidId;
        FundDetail storage fundDetail = lenderPoolFundDetails[msg.sender][
            _poolId
        ][_ERC20Address][_bidId];
        fundDetail.amount = _amount;
        fundDetail.expiration = _expiration;
        fundDetail.maxDuration = _maxLoanDuration;
        fundDetail.interestRate = _APR;
        fundDetail.bidTimestamp = uint32(block.timestamp);

        fundDetail.state = BidState.PENDING;
        fundDetail.installment.installments = _maxLoanDuration / 30 days;
        fundDetail.installment.installmentsPaid = 0;
        fundDetail.installment.protocolFee = fee;

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        fundDetail.paymentCycleAmount = LibCalculations.payment(
            _amount,
            fundDetail.maxDuration,
            paymentCycle,
            fundDetail.interestRate
        );

        uint256 monthlyPrincipal = _amount /
            fundDetail.installment.installments;

        fundDetail.installment.monthlyCycleInterest =
            fundDetail.paymentCycleAmount -
            monthlyPrincipal;

        fundDetail.installment.defaultDuration = poolRegistry(
            poolRegistryAddress
        ).getPaymentDefaultDuration(_poolId);

        address _poolAddress = poolRegistry(poolRegistryAddress).getPoolAddress(
            _poolId
        );

        bidId++;

        // Send payment to the Pool
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                _poolAddress,
                _amount
            ),
            "Unable to tansfer to poolAddress"
        );

        emit SuppliedToPool(
            msg.sender,
            _poolId,
            _bidId,
            _ERC20Address,
            _amount
        );
    }

    /**
     * @notice Accepts the specified bid to supply to the pool.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the bid funds being accepted.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     * @param _receiver The address of the funds receiver.
     */
    function AcceptBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender,
        address _receiver
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "pool closed"
        );
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.PENDING) {
            revert("Bid must be pending");
        }
        require(
            fundDetail.expiration >= uint32(block.timestamp),
            "bid expired"
        );
        fundDetail.acceptBidTimestamp = uint32(block.timestamp);
        fundDetail.lastRepaidTimestamp = uint32(block.timestamp);
        uint256 amount = fundDetail.amount;
        fundDetail.state = BidState.ACCEPTED;

        address AconomyOwner = poolRegistry(poolRegistryAddress)
            .getAconomyOwner();

        //Aconomy Fee
        uint256 amountToAconomy = LibCalculations.percent(
            amount,
            fundDetail.installment.protocolFee
        );

        // transfering Amount to Owner
        require(
            IERC20(_ERC20Address).transfer(_receiver, amount - amountToAconomy),
            "unable to transfer to receiver"
        );

        // transfering Amount to Protocol Owner
        if (amountToAconomy != 0) {
            require(
                IERC20(_ERC20Address).transfer(AconomyOwner, amountToAconomy),
                "Unable to transfer to AconomyOwner"
            );
        }

        emit BidAccepted(
            _lender,
            _receiver,
            _bidId,
            _poolId,
            amount,
            fundDetail.paymentCycleAmount
        );
    }

    /**
     * @notice Rejects the bid to supply to the pool.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds contract.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     */
    function RejectBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        require(
            !poolRegistry(poolRegistryAddress).ClosedPool(_poolId),
            "pool closed"
        );
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.PENDING) {
            revert("Bid must be pending");
        }
        fundDetail.state = BidState.REJECTED;
        // transfering Amount to Lender
        require(
            IERC20(_ERC20Address).transfer(_lender, fundDetail.amount),
            "unable to transfer to receiver"
        );
        emit BidRejected(_lender, _bidId, _poolId, fundDetail.amount);
    }

    /**
     * @notice Checks if bid has expired.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds contract.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     */
    function isBidExpired(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (bool) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        if (fundDetail.state != BidState.PENDING) return false;
        if (fundDetail.expiration == 0) return false;

        return (uint32(block.timestamp) > fundDetail.expiration);
    }

    /**
     * @notice Checks if loan is defaulted.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the funds contract.
     * @param _bidId The Id of the bid.
     * @param _lender The address of the lender.
     */
    function isLoanDefaulted(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (bool) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        // Make sure loan cannot be liquidated if it is not active
        if (fundDetail.state != BidState.ACCEPTED) return false;

        if (fundDetail.installment.defaultDuration == 0) return false;

        return ((int32(uint32(block.timestamp)) -
            int32(fundDetail.acceptBidTimestamp + fundDetail.maxDuration)) >
            int32(fundDetail.installment.defaultDuration));
    }

    /**
     * @notice Checks if loan repayment is late.
     * @dev Returned value is type boolean.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return boolean of late payment.
     */
    function isPaymentLate(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (bool) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) return false;
        return
            uint32(block.timestamp) >
            calculateNextDueDate(_poolId, _ERC20Address, _bidId, _lender) +
                7 days;
    }

    /**
     * @notice Calculates and returns the next due date.
     * @dev Returned value is type uint256.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return dueDate_ unix time of due date in uint256.
     */
    function calculateNextDueDate(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (uint256 dueDate_) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) return dueDate_;

        uint256 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        // Start with the original due date being 1 payment cycle since loan was accepted
        dueDate_ = fundDetail.acceptBidTimestamp + paymentCycle;

        // Calculate the cycle number the last repayment was made
        uint32 delta = fundDetail.lastRepaidTimestamp -
            fundDetail.acceptBidTimestamp;
        if (delta > 0) {
            uint256 repaymentCycle = (delta / paymentCycle);
            dueDate_ += (repaymentCycle * paymentCycle);
        }

        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (dueDate_ > fundDetail.acceptBidTimestamp + fundDetail.maxDuration) {
            dueDate_ = fundDetail.acceptBidTimestamp + fundDetail.maxDuration;
        }
    }

    /**
     * @notice Returns the installment amount to be paid at the called timestamp.
     * @dev Returned value is type uint256.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return installment amount in uint256.
     */
    function viewInstallmentAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external view returns (uint256) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        uint32 LastRepaidTimestamp = fundDetail.lastRepaidTimestamp;
        uint256 lastPaymentCycle = BPBDTL.diffMonths(
            fundDetail.acceptBidTimestamp,
            LastRepaidTimestamp
        );
        uint256 monthsSinceStart = BPBDTL.diffMonths(
            fundDetail.acceptBidTimestamp,
            block.timestamp
        );

        if (
            fundDetail.installment.installmentsPaid + 1 ==
            fundDetail.installment.installments
        ) {
            return viewFullRepayAmount(_poolId, _ERC20Address, _bidId, _lender);
        }

        if (monthsSinceStart > lastPaymentCycle) {
            return fundDetail.paymentCycleAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Repays the monthly installment.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function repayMonthlyInstallment(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        require(fundDetail.amount / fundDetail.installment.installments >= 1000000, "low");
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Loan must be accepted");
        }
        require(
            fundDetail.installment.installmentsPaid + 1 <=
                fundDetail.installment.installments
        );
        require(
            block.timestamp >
                calculateNextDueDate(_poolId, _ERC20Address, _bidId, _lender)
        );

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        if (
            fundDetail.installment.installmentsPaid + 1 ==
            fundDetail.installment.installments
        ) {
            _repayFullAmount(_poolId, _ERC20Address, _bidId, _lender);
        } else {
            uint256 monthlyInterest = fundDetail
                .installment
                .monthlyCycleInterest;
            uint256 monthlyDue = fundDetail.paymentCycleAmount;
            uint256 due = monthlyDue - monthlyInterest;

            (uint256 owedAmount, , uint256 interest) = LibCalculations
                .calculateInstallmentAmount(
                    fundDetail.amount,
                    fundDetail.Repaid.amount,
                    fundDetail.interestRate,
                    fundDetail.paymentCycleAmount,
                    paymentCycle,
                    fundDetail.lastRepaidTimestamp,
                    block.timestamp,
                    fundDetail.acceptBidTimestamp,
                    fundDetail.maxDuration
                );

            fundDetail.installment.installmentsPaid++;

            _repayBid(
                _poolId,
                _ERC20Address,
                _bidId,
                _lender,
                due,
                monthlyInterest,
                owedAmount + interest
            );

            fundDetail.lastRepaidTimestamp =
                fundDetail.acceptBidTimestamp +
                (fundDetail.installment.installmentsPaid * paymentCycle);
        }
    }

    /**
     * @notice Returns the full amount to be repaid.
     * @dev Returned value is type uint256.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @return Full amount to be paid in uint256.
     */
    function viewFullRepayAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) public view returns (uint256) {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (
            fundDetail.state != BidState.ACCEPTED ||
            fundDetail.state == BidState.PAID
        ) {
            return 0;
        }
        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        (uint256 owedAmount, , uint256 interest) = LibCalculations
            .calculateInstallmentAmount(
                fundDetail.amount,
                fundDetail.Repaid.amount,
                fundDetail.interestRate,
                fundDetail.paymentCycleAmount,
                paymentCycle,
                fundDetail.lastRepaidTimestamp,
                block.timestamp + 10 minutes,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        uint256 paymentAmount = owedAmount + interest;
        return paymentAmount;
    }

    /**
     * @notice Repays the full amount for the loan.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function _repayFullAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) private {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Bid must be accepted");
        }

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        (uint256 owedAmount, , uint256 interest) = LibCalculations
            .calculateInstallmentAmount(
                fundDetail.amount,
                fundDetail.Repaid.amount,
                fundDetail.interestRate,
                fundDetail.paymentCycleAmount,
                paymentCycle,
                fundDetail.lastRepaidTimestamp,
                block.timestamp,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        _repayBid(
            _poolId,
            _ERC20Address,
            _bidId,
            _lender,
            owedAmount,
            interest,
            owedAmount + interest
        );

        emit FullAmountRepaid(_poolId, _bidId, owedAmount, interest);
    }

    /**
     * @notice Repays the full amount for the loan.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function RepayFullAmount(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        require(poolOwner == msg.sender, "You are not the Pool Owner");
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];
        if (fundDetail.state != BidState.ACCEPTED) {
            revert("Bid must be accepted");
        }

        uint32 paymentCycle = poolRegistry(poolRegistryAddress)
            .getPaymentCycleDuration(_poolId);

        (uint256 owedAmount, , uint256 interest) = LibCalculations
            .calculateInstallmentAmount(
                fundDetail.amount,
                fundDetail.Repaid.amount,
                fundDetail.interestRate,
                fundDetail.paymentCycleAmount,
                paymentCycle,
                fundDetail.lastRepaidTimestamp,
                block.timestamp,
                fundDetail.acceptBidTimestamp,
                fundDetail.maxDuration
            );
        _repayBid(
            _poolId,
            _ERC20Address,
            _bidId,
            _lender,
            owedAmount,
            interest,
            owedAmount + interest
        );

        emit FullAmountRepaid(_poolId, _bidId, owedAmount, interest);
    }

    /**
     * @notice Repays the specified amount for the loan.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     * @param _amount The amount being repaid.
     * @param _interest The interest being repaid.
     * @param _owedAmount The total owed amount at the called timestamp.
     */
    function _repayBid(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender,
        uint256 _amount,
        uint256 _interest,
        uint256 _owedAmount
    ) internal {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        uint256 paymentAmount = _amount + _interest;

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;

            fundDetail.state = BidState.PAID;
            emit BidRepaid(_bidId, paymentAmount);
        } else {
            emit BidRepayment(_bidId, paymentAmount);
        }

        fundDetail.Repaid.amount += _amount;
        fundDetail.Repaid.interest += _interest;
        fundDetail.lastRepaidTimestamp = uint32(block.timestamp);

        // Send payment to the lender
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                _lender,
                paymentAmount
            ),
            "unable to transfer to lender"
        );
    }

    /**
     * @notice Allows the lender to withdraw the loan bid if it is still pending.
     * @param _poolId The Id of the pool.
     * @param _ERC20Address The address of the erc20 funds.
     * @param _bidId The Id of the bid.
     * @param _lender The lender address.
     */
    function Withdraw(
        uint256 _poolId,
        address _ERC20Address,
        uint256 _bidId,
        address _lender
    ) external nonReentrant {
        FundDetail storage fundDetail = lenderPoolFundDetails[_lender][_poolId][
            _ERC20Address
        ][_bidId];

        if (fundDetail.state != BidState.PENDING) {
            revert("Bid must be pending");
        }

        // Check is lender the calling the function
        if (_lender != msg.sender) {
            revert("You are not a Lender");
        }

        require(
            fundDetail.expiration < uint32(block.timestamp),
            "You can't Withdraw"
        );

        fundDetail.state = BidState.WITHDRAWN;

        // Transfering the amount to the lender
        require(
            IERC20(_ERC20Address).transfer(_lender, fundDetail.amount),
            "Unable to transfer to lender"
        );

        emit Withdrawn(_lender, _bidId, _poolId, fundDetail.amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./AttestationRegistry.sol";
import "./interfaces/IAttestationServices.sol";
import "./interfaces/IAttestationRegistry.sol";

contract AttestationServices {
    // The AS global registry.
    IAttestationRegistry private immutable _asRegistry;
    address AttestationRegistryAddress;

    constructor(IAttestationRegistry registry) {
        if (address(registry) == address(0x0)) {
            revert("InvalidRegistry");
        }
        _asRegistry = registry;
        // AttestationRegistryAddress=_asRegistry;
    }

    struct Attestation {
        // A unique identifier of the attestation.
        bytes32 uuid;
        // A unique identifier of the AS.
        bytes32 schema;
        // The recipient of the attestation.
        address recipient;
        // The attester/sender of the attestation.
        address attester;
        // The time when the attestation was created (Unix timestamp).
        uint256 time;
        // The time when the attestation was revoked (Unix timestamp).
        uint256 revocationTime;
        // Custom attestation data.
        bytes data;
    }

    // The global counter for the total number of attestations.
    uint256 private _attestationsCount;

    bytes32 private constant EMPTY_UUID = 0;

    // The global mapping between attestations and their UUIDs.
    mapping(bytes32 => Attestation) private _db;

    /**
     *  Triggered when an attestation has been made.
     ~recipient The recipient of the attestation.
     ~attester The attesting account.
     ~uuid The UUID the revoked attestation.
     ~schema The UUID of the AS.
     */
    event Attested(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    event Revoked(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    function getASRegistry() external view returns (IAttestationRegistry) {
        return _asRegistry;
    }

     /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     *
     * @return The UUID of the new attestation.
     */
    function attest(
        address recipient,
        bytes32 schema,
        bytes calldata data
    ) public virtual returns (bytes32) {
        return _attest(recipient, schema, data, msg.sender);
    }

     /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param uuid The UUID of the attestation to revoke.
     */
    function revoke(bytes32 uuid) public virtual {
        _revoke(uuid, msg.sender);
    }

    function _attest(
        address recipient,
        bytes32 schema,
        bytes calldata data,
        address attester
    ) private returns (bytes32) {

        IAttestationRegistry.ASRecord memory asRecord = _asRegistry.getAS(
            schema
        );
        if (asRecord.uuid == EMPTY_UUID) {
            revert("InvalidSchema");
        }

        Attestation memory attestation = Attestation({
            uuid: EMPTY_UUID,
            schema: schema,
            recipient: recipient,
            attester: attester,
            time: block.timestamp,
            revocationTime: 0,
            data: data
        });

        bytes32 _lastUUID;
        _lastUUID = _getUUID(attestation);
        attestation.uuid = _lastUUID;

        _db[_lastUUID] = attestation;
        _attestationsCount++;

        emit Attested(recipient, attester, _lastUUID, schema);

        return _lastUUID;
    }

    function _revoke(bytes32 uuid, address attester) private {
        Attestation storage attestation = _db[uuid];
        if (attestation.uuid == EMPTY_UUID) {
            revert("Not found");
        }

        if (attestation.attester != attester) {
            revert("Access denied");
        }

        if (attestation.revocationTime != 0) {
            revert ("Already Revoked");
        }

        attestation.revocationTime = block.timestamp;

        emit Revoked(attestation.recipient, attester, uuid, attestation.schema);
    }

    function _getUUID(Attestation memory attestation)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    attestation.schema,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.data,
                    _attestationsCount
                )
            );
    }

    /**
     * @dev Checks whether an attestation is active.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation is active.
     */
    function isAddressActive(bytes32 uuid) public view returns (bool) {
        return
            isAddressValid(uuid) &&
            _db[uuid].revocationTime == 0;
    }

     /**
     * @dev Checks whether an attestation exists.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAddressValid(bytes32 uuid) public view returns (bool) {
        return _db[uuid].uuid != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IAttestationServices.sol";
import "./interfaces/IAttestationRegistry.sol";

contract AttestationRegistry is IAttestationRegistry {
    mapping(bytes32 => ASRecord) public _registry;
    bytes32 private constant EMPTY_UUID = 0;
    event Registered(
        bytes32 indexed uuid,
        uint256 indexed index,
        bytes schema,
        address attester
    );

    uint256 private _asCount;

    function register(bytes calldata schema)
        external
        override
        returns (bytes32)
    {
        uint256 index = ++_asCount;
        bytes32 uuid = _getUUID(schema);
        if (_registry[uuid].uuid != EMPTY_UUID) {
            revert("AlreadyExists");
        }

        ASRecord memory asRecord = ASRecord({
            uuid: uuid,
            index: index,
            schema: schema
        });

        _registry[uuid] = asRecord;

        emit Registered(uuid, index, schema, msg.sender);

        return uuid;
    }

    function _getUUID(bytes calldata schema) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(schema));
    }

    function getAS(bytes32 uuid)
        external
        view
        override
        returns (ASRecord memory)
    {
        return _registry[uuid];
    }
}

pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

contract AconomyFee is Ownable {
    uint16 public _AconomyPoolFee;
    uint16 public _AconomyPiMarketFee;
    uint16 public _AconomyNFTLendBorrowFee;

    event SetAconomyPoolFee(uint16 newFee, uint16 oldFee);
    event SetAconomyPiMarketFee(uint16 newFee, uint16 oldFee);
    event SetAconomyNFTLendBorrowFee(uint16 newFee, uint16 oldFee);

    function AconomyPoolFee() public view returns (uint16) {
        return _AconomyPoolFee;
    }

    function AconomyPiMarketFee() public view returns (uint16) {
        return _AconomyPiMarketFee;
    }

    function AconomyNFTLendBorrowFee() public view returns (uint16) {
        return _AconomyNFTLendBorrowFee;
    }

    function getAconomyOwnerAddress() public view returns (address) {
        return owner();
    }

    /**
     * @notice Sets the protocol fee.
     * @param newFee The value of the new fee percentage in bps.
     */
    function setAconomyPoolFee(uint16 newFee) public onlyOwner {
        if (newFee == _AconomyPoolFee) return;

        uint16 oldFee = _AconomyPoolFee;
        _AconomyPoolFee = newFee;
        emit SetAconomyPoolFee(newFee, oldFee);
    }

    function setAconomyPiMarketFee(uint16 newFee) public onlyOwner {
        if (newFee == _AconomyPiMarketFee) return;

        uint16 oldFee = _AconomyPiMarketFee;
        _AconomyPiMarketFee = newFee;
        emit SetAconomyPiMarketFee(newFee, oldFee);
    }

    function setAconomyNFTLendBorrowFee(uint16 newFee) public onlyOwner {
        if (newFee == _AconomyNFTLendBorrowFee) return;

        uint16 oldFee = _AconomyNFTLendBorrowFee;
        _AconomyNFTLendBorrowFee = newFee;
        emit SetAconomyNFTLendBorrowFee(newFee, oldFee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 * ```
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
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
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
            set._indexes[value] = set._values.length;
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
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}