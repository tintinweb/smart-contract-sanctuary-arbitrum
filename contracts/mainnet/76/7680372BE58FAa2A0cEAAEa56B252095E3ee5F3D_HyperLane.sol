// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

/*@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@ Gas Refill @@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@*/


interface IMailbox {
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageId);

    function process(bytes calldata _metadata, bytes calldata _message) external;

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable;

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee);

}

library TypeCasts {
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}


contract HyperLane {
    IMailbox public mailbox;
    bytes32 public allowed_contract;
    address public owner;
    uint256 public maximumFee;
    uint256 public platformFeePercent; // Platform fee in percentage

    event ReceivedMessage(uint32 indexed origin, bytes32 indexed sender, uint256 value, string message);
    event EtherDeposited(address indexed from, uint256 amount);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event ExtraGasStored(uint256 amount);
    event ExtraGasReleased(address indexed to, uint256 amount);
    event PlatformFeeSet(uint256 feePercent);
    event MaximumFeeSet(uint256 maxFee);

    constructor(address _mailbox,address _owner) {
        mailbox = IMailbox(_mailbox);
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyMailbox() {
        require(
            msg.sender == address(mailbox),
            "MailboxClient: sender not mailbox"
        );
        _;
    }

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 extraGasAmount

    ) external payable returns (bytes32 messageId) {
        
        uint256 fee = mailbox.quoteDispatch(destinationDomain, recipientAddress, abi.encode(msg.value, msg.sender));

        uint256 platformFee = (msg.value * platformFeePercent) / 100;

        uint256 totalFee = fee + platformFee;

        require(msg.value >= totalFee, "Insufficient Ether to cover fees");

        // Store the extra gas amount in the contract balance
        uint256 extraGas = (msg.value - totalFee);

        require(extraGas <= maximumFee, "Extra gas amount exceeds maximum fee");

        bytes32 _messageId = mailbox.dispatch{value: fee}(
            destinationDomain,
            recipientAddress,
            abi.encode(extraGas, msg.sender)
        );

        emit ExtraGasStored(extraGas);
        return _messageId;
    }
 
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual onlyMailbox {

        require(_sender == allowed_contract, "Caller not allowed contract");

        (uint256 extraGasAmount, address recipient) = abi.decode(_data, (uint256, address));

        address receiver = TypeCasts.bytes32ToAddress(_sender);

        payable(recipient).transfer(extraGasAmount);

        emit ReceivedMessage(_origin, _sender, msg.value, string(_data));

        emit ExtraGasReleased(receiver, extraGasAmount);
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function depositEther() external payable {
        require(msg.value > 0, "Must send ether to deposit");
        emit EtherDeposited(msg.sender, msg.value);
    }

    function withdrawEther(uint256 amount, address _address) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance in contract");
        payable(_address).transfer(amount);
        emit EtherWithdrawn(_address, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setAllowedContract(bytes32 _allowedContract) external onlyOwner {
        allowed_contract = _allowedContract;
    }

    function getFee(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 value
    ) view public returns (uint256) {
        return mailbox.quoteDispatch(destinationDomain, recipientAddress, abi.encode(value));
    }


    function setMaximumFee(uint256 _maximumFeeEther) public onlyOwner {
        maximumFee = _maximumFeeEther * 1 wei;
        emit MaximumFeeSet(maximumFee);
    }

    function setPlatformFee(uint256 _platformFeePercent) public onlyOwner {
        platformFeePercent = _platformFeePercent;
        emit PlatformFeeSet(_platformFeePercent);
    }

    function setMailbox(address _mailBox) public onlyOwner {
        mailbox = IMailbox(_mailBox);
    }
}


contract checkTest{

    function checkValue(uint256 value) public payable  returns(uint256,uint256,uint256){
        return (msg.value,1 wei,value);
    }
}






//sepolia : 0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766  11155111
//fuji : 0x5b6CFf85442B851A8e6eaBd2A4E4507B5135B3B0   43113
//bsctestnet : 0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D   97
//scroll sepolia : 0x3C5154a193D6e2955650f9305c8d80c18C814A68 534351