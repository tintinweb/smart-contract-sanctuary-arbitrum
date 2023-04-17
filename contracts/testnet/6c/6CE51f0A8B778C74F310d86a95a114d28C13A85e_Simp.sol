/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

pragma solidity ^0.8.18;

error NotTheQueen();
error NotTheQueenOrAMod();
error NotAMod();
error NotEnoughStartingMods();
error MerchHasExpired();
error MerchHasNotExpired();
error TransferEtherFailed();
error DonationTooSmall();
error ExpiryReductionNotAllowed();
error NoPendingRefund();
error NotEnoughSignatures();
error SignaturesNotInAscendingOrder();
error InvalidSignature();
error NotModSignature();
error SignatureExpired();
error InvalidModThreshold();
error IsAMod();

/**
@title Simp - A Crowdfunding Contract
@notice This smart contract functions as a specialized escrow for crowdfunding. 
        It involves three parties, the recipient (queen), the donors (simps) and
        the judges (mods). Any of the mods or queen can create donation escrow (merch)
        with certain promise that allows anyone to donate. If the promise is not fulfilled,
        any of the mods or queen can mark the merch as expired and donated simps need to
        retrieve the refund themselves. If the promise is fulfilled, any of the mod can 
        send the collected fund to queen. The merchs are created with expiration dates 
        so simps can refund themselves in case something happen. Simps can also donate 
        for text-to-speech (tts) message that will be shown in website if they are 
        supported. Mods can never access any stored fund.
@dev Queen can change their wallet address at any time. Any of the mods or queen can update
     merch details. The mods can elect new mod or depose existing mod as long as the number of
     mods approving the decision meets the `modThreshold` number. They need to sign the
     decision off-chain using eip-712 multisig and submit it later. The `modThreshold` number
     can be changed through the same process too.
*/
contract Simp {
    /**
    Donation escrow
    If amount and expiry are 0, it means either the fund was released or everyone got their refund.
    @param name Name of the donation escrow
    @param imageURI Image link for the donation escrow
    @param target Target donation
    @param amount Amount of current donation 
    @param expiry Expiry timestamp
    @param simpToAmount Check amount donated by address
    */
    struct Merch {
        string name;
        string imageURI;
        uint target;
        uint amount;
        uint expiry;
        mapping(address => uint) simpToAmount;
    }

    /**
    Signature for eip-712 multisig
    @param signer address of signer
    @param v signature component
    @param r signature component
    @param s signature component
    */
    struct Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// domain separator implemented according to eip-712
    bytes32 immutable DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("Simp")), 
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );
    /// Total number of mods
    uint public modCount;
    /// Number of mods required for governance decision
    uint public modThreshold = 2;
    /// Check whether address is mod
    mapping(address => bool) public isMod;
    /// Recipient of the contract
    address public queen;
    /**
    List of donation escrow
    @dev Due to nature of mapping and gas, the array will always leaves a gap even
         if the donation escrow is completed.
    */
    Merch[] public merchs;

    event TTSDonated(address indexed simp, string message, uint amount);
    event Donated(address indexed simp, uint indexed merchId, uint amount);
    event Refunded(address indexed simp, uint indexed merchId, uint amount);
    event ReleaseApproved(address approver, uint merchId);
    event RefundApproved(address approver, uint merchId);
    event MerchChanged(uint indexed merchId, string name, string imageURI, uint target, uint expiry);
    event ModChanged(address[] approvers, address mod, bool isPromoted);
    event ThresholdUpdated(address[] approvers, uint newThreshold);

    modifier onlyQueen() {
        if (msg.sender != queen) revert NotTheQueen();
        _;
    }

    modifier onlyMod() {
        if (!isMod[msg.sender]) revert NotAMod();
        _;
    }

    modifier onlyQueenOrMod() {
        if (!isMod[msg.sender] && msg.sender != queen) revert NotTheQueenOrAMod();
        _;
    }
    
    /** 
    Creates the crowdfunding contract
    @param _queen Recipient of the escrows
    @param _mods list of judges
    */
    constructor(address _queen, address[] memory _mods) {
        queen = _queen;
        modCount = _mods.length;
        if (modCount < modThreshold) revert NotEnoughStartingMods();

        for (uint i = 0; i < _mods.length; ++i) {
            address mod = _mods[i];
            isMod[mod] = true;
            emit ModChanged(new address[](0), mod, true);
        }
    }   

    receive() external payable {} // contract needs receive() to receive ether

    /**
    Donates to an escrow. Needs to set `msg.value`.
    @param _merchId array index of merch in `merchs`
    */
    function donate(uint _merchId) public payable {
        Merch storage merch = merchs[_merchId];
        if (merch.expiry < block.timestamp) revert MerchHasExpired();

        mapping(address => uint) storage simpToAmount = merch.simpToAmount;
        simpToAmount[msg.sender] += msg.value;
        merch.amount += msg.value;

        emit Donated(msg.sender, _merchId, msg.value);
        (bool success, ) = address(this).call{value: msg.value}("");
        if (!success) revert TransferEtherFailed();
    }

    /**
    Donates to show a message. Needs to set `msg.value`.
    @param _message message to be shown
    */
    function donateTTS(string calldata _message) public payable {
        if (msg.value < 1) revert DonationTooSmall();
        emit TTSDonated(msg.sender, _message, msg.value);
        (bool success, ) = queen.call{value: msg.value}("");
        if (!success) revert TransferEtherFailed();
    }

    /**
    Release the fund to queen (after promise fulfilled)
    @param _merchId index of merch in `merchs` array
    */
    function releaseFund(uint _merchId) public onlyMod {
        Merch storage merch = merchs[_merchId];
        if (merch.expiry < block.timestamp) revert MerchHasExpired();
        uint amount = merch.amount;
        delete merchs[_merchId];
        emit ReleaseApproved(msg.sender, _merchId);
        (bool success, ) = queen.call{value: amount}("");
        if (!success) revert TransferEtherFailed();
    }

    /**
    Allows simps to withdraw donated funds
    @param _merchId index of merch in `merchs` array
    */
    function approveRefund(uint _merchId) public onlyQueenOrMod {
        Merch storage merch = merchs[_merchId];
        merch.expiry = 0;
        emit RefundApproved(msg.sender, _merchId);
    }

    /**
    Returns donated fund back.
    @param _merchId index of merch in `merchs` array
    @param _simp address of donor
    */
    function refund(uint _merchId, address payable _simp) public {
        Merch storage merch = merchs[_merchId];
        if (merch.expiry > block.timestamp) revert MerchHasNotExpired();
        uint amount = merch.simpToAmount[_simp];
        if (merch.amount < amount || merch.amount == 0) revert NoPendingRefund();
        merch.amount -= amount;
        delete merch.simpToAmount[_simp];
        if (merch.amount == 0) delete merchs[_merchId];
        emit Refunded(_simp, _merchId, amount);
        
        (bool success, ) = _simp.call{value: amount}("");
        if (!success) revert TransferEtherFailed();
    }

    /**
    Creates a donation escrow.
    @param _name name of the donation escrow
    @param _imageURI image link for the donation escrow
    @param _target donation target
    @param _expiry expiry timestamp
    */
    function createMerch(
        string calldata _name, string calldata _imageURI, 
        uint _target, uint _expiry
    ) public onlyQueenOrMod returns (uint) {
        Merch storage newMerch = merchs.push();
        newMerch.name = _name;
        newMerch.imageURI = _imageURI;
        newMerch.target = _target;
        newMerch.expiry = _expiry;
        uint newId = merchs.length - 1;

        emit MerchChanged(newId, newMerch.name, newMerch.imageURI, newMerch.target, newMerch.expiry);
        return newId;
    }

    /**
    Update a donation escrow properties.
    @param _merchId index of escrow in `merchs` array
    @param _name name of the donation escrow
    @param _imageURI image link for the donation escrow
    @param _target donation target
    @param _expiry expiry timestamp
    */
    function updateMerch(
        uint _merchId, string calldata _name, string calldata _imageURI, 
        uint _target, uint _expiry
    ) public onlyQueenOrMod {
        Merch storage merch = merchs[_merchId];
        if (merch.expiry < block.timestamp) revert MerchHasExpired();
        if (_expiry < merch.expiry) revert ExpiryReductionNotAllowed();
        // provide the same value as original if you don't want to change them
        merch.name = _name;
        merch.imageURI = _imageURI;
        merch.target = _target;
        merch.expiry = _expiry;

        emit MerchChanged(_merchId, merch.name, merch.imageURI, merch.target, merch.expiry);
    }

    /**
    Transfer role of queen to another address
    @param _newQueen address of the new queen
    */
    function abdicate(address _newQueen) public onlyQueen {
        queen = _newQueen;
    }

    /**
    Promote an address to become a mod after getting enough signatures
    @param _mod mod to be promoted
    @param _deadline expiry time of signature
    @param _signatures signatures of approved mods
    */
    function promoteMod(address _mod, uint _deadline, Signature[] calldata _signatures) public {
        _requireModSignatures(_hashPromoteMod(_mod, _deadline), _signatures);
        if (_deadline < block.timestamp) revert SignatureExpired();
        if (isMod[_mod]) revert IsAMod();
        ++modCount;
        isMod[_mod] = true;
        emit ModChanged(_signaturesToSigners(_signatures), _mod, true);
    }

    /**
    Demote a mod after getting enough signatures
    @param _mod mod to be demoted
    @param _deadline expiry time of signature
    @param _signatures signatures of approved mods
    */
    function demoteMod(address _mod, uint _deadline, Signature[] calldata _signatures) public {
        _requireModSignatures(_hashDemoteMod(_mod, _deadline), _signatures);
        if (_deadline < block.timestamp) revert SignatureExpired();
        if (!isMod[_mod]) revert NotAMod();
        --modCount;
        isMod[_mod] = false;
        emit ModChanged(_signaturesToSigners(_signatures), _mod, false);
    }

    /**
    Update minimum number of mod requires for governance decision after getting
    enough signatures. Make sure not to set it too low or too high or future governance
    decisions may no longer be possible.
    @param _threshold minimum number of mod requires for governance decision
    @param _deadline expiry time of signature
    @param _signatures signatures of approved mods
    */
    function updateModThreshold(uint _threshold, uint _deadline, Signature[] calldata _signatures) public {
        _requireModSignatures(_hashUpdateThreshold(_threshold, _deadline), _signatures);
        if (_deadline < block.timestamp) revert SignatureExpired();
        if (_threshold < 1 || _threshold > modCount) revert InvalidModThreshold();
        modThreshold = _threshold; 
        emit ThresholdUpdated(_signaturesToSigners(_signatures), _threshold);
    }

    /**
    Total number of merchs
    */
    function merchCount() public view returns (uint) {
        return merchs.length;
    }

    /**
    Amount donated to an escrow by an address
    @param _merchId index of merch in `merchs` array
    @param _simp address of donor
    */
    function donatedAmount(uint _merchId, address _simp) public view returns (uint) {
        return merchs[_merchId].simpToAmount[_simp];
    }

    /**
    Check whether enough mod signatures are given and whether they are valid using provided hash.
    Signatures must be provided in ascending order according to address
    @param _hash hash of the signed message
    @param _signatures array of `Signature` signed by mods, given in ascending order
    */
    function _requireModSignatures(bytes32 _hash, Signature[] calldata _signatures) private view {
        uint length = _signatures.length;
        if (length < modThreshold) revert NotEnoughSignatures();

        address lastSigner = address(0);
        for (uint i = 0; i < modThreshold || i < _signatures.length; ++i) {
            // verify signers address
            Signature calldata signature = _signatures[i];
            address signer = signature.signer;
            if (!isMod[signer]) revert NotModSignature();
            // Signatures in ascending order based on signer address
            if (signer <= lastSigner) revert SignaturesNotInAscendingOrder(); 
            lastSigner = signer;

            // verify signatures
            if (signer != ecrecover(_hash, signature.v, signature.r, signature.s)) {
                revert InvalidSignature();
            }
        }        
    }

    function _hashPromoteMod(address _mod, uint _deadline) private view returns (bytes32) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("PromoteMod(address _mod,uint256 _deadline)"),
                _mod,
                _deadline
            )
        );

        return keccak256(abi.encodePacked(
            uint16(0x1901),
            DOMAIN_SEPARATOR,
            hashStruct
        ));
    }

    function _hashDemoteMod(address _mod, uint _deadline) private view returns (bytes32) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("DemoteMod(address _mod,uint256 _deadline)"),
                _mod,
                _deadline
            )
        );

        return keccak256(abi.encodePacked(
            uint16(0x1901),
            DOMAIN_SEPARATOR,
            hashStruct
        ));
    }

    function _hashUpdateThreshold(uint _threshold, uint _deadline) private view returns (bytes32) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("UpdateModThreshold(uint256 _threshold,uint256 _deadline)"),
                _threshold,
                _deadline
            )
        );

        return keccak256(abi.encodePacked(
            uint16(0x1901),
            DOMAIN_SEPARATOR,
            hashStruct
        ));
    }

    /**
    Convert array of `Signature` to array of signers address
    @param _signatures signatures to be converted
    */
    function _signaturesToSigners(Signature[] calldata _signatures) private pure returns (address[] memory) {
        uint length = _signatures.length;
        address[] memory signers = new address[](length);
        for (uint i = 0; i < length; ++i)
            signers[i] = _signatures[i].signer;
        return signers;
    }
}